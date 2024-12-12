"""
Copyright ©2024. The Regents of the University of California (Regents). All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its documentation
for educational, research, and not-for-profit purposes, without fee and without a
signed licensing agreement, is hereby granted, provided that the above copyright
notice, this paragraph and the following two paragraphs appear in all copies,
modifications, and distributions.

Contact The Office of Technology Licensing, UC Berkeley, 2150 Shattuck Avenue,
Suite 510, Berkeley, CA 94720-1620, (510) 643-7201, otl@berkeley.edu,
http://ipira.berkeley.edu/industry-info for commercial licensing opportunities.

IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF
THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS HAS BEEN ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED
"AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
ENHANCEMENTS, OR MODIFICATIONS.
"""

from urllib.parse import urlencode, urljoin, urlparse

import cas
from damien.api.errors import ResourceNotFoundError
from damien.lib.http import add_param_to_url, tolerant_jsonify
from damien.merged.user_session import UserSession
from damien.models.user import User
from flask import abort, current_app as app, flash, redirect, request, url_for
from flask_login import current_user, login_required, login_user, logout_user


@app.route('/cas/callback', methods=['GET', 'POST'])
def cas_login():
    ticket = request.args['ticket']
    target_url = request.args.get('url')
    uid, attributes, proxy_granting_ticket = _cas_client(target_url).verify_ticket(ticket)
    app.logger.info(f'Logged into CAS as user {uid}')
    user = User.find_by_uid(uid)
    if _is_authorized_user(user):
        _login(user)
        if _is_safe_url(request.args.get('next')):
            # Is safe URL per https://flask-login.readthedocs.io/en/latest/
            flash('Logged in successfully.')
            redirect_url = target_url or '/'
        else:
            return abort(400)
    else:
        app.logger.error(f'UID {uid} is not an authorized user.')
        param = ('error', f"""
            Sorry, you are not registered to use Course Evaluations.
            Please <a href="mailto:{app.config['EMAIL_COURSE_EVALUATION_ADMIN']}">email us</a> for assistance.
        """)
        redirect_url = add_param_to_url('/', param)
    return redirect(redirect_url)


@app.route('/api/auth/cas_login_url', methods=['GET'])
def cas_login_url():
    target_url = request.referrer or None
    return tolerant_jsonify({
        'casLoginUrl': _cas_client(target_url).get_login_url(),
    })


@app.route('/api/auth/dev_auth_login', methods=['POST'])
def dev_auth_login():
    params = request.get_json() or {}
    if app.config['DEVELOPER_AUTH_ENABLED']:
        password = params.get('password')
        if password != app.config['DEVELOPER_AUTH_PASSWORD']:
            return tolerant_jsonify({'message': 'Invalid credentials'}, 401)
        uid = params.get('uid')
        user = User.find_by_uid(uid)
        if _is_authorized_user(user):
            app.logger.info(f'Dev-auth used to log in as UID {uid}')
            authenticated = _login(user) and current_user.is_authenticated
            if authenticated:
                return tolerant_jsonify(current_user.to_api_json())
            return tolerant_jsonify({'message': f'User {user.id} failed to authenticate.'}, 403)
        else:
            app.logger.error(f'UID {uid} is not an authorized user.')
            return tolerant_jsonify({'message': f'Sorry, user with UID {uid} is not registered to use Damien.'}, 403)
    else:
        raise ResourceNotFoundError('Unknown path')


@app.route('/api/auth/logout')
@login_required
def logout():
    logout_user()
    redirect_url = app.config['VUE_LOCALHOST_BASE_URL'] or request.url_root
    cas_logout_url = _cas_client().get_logout_url(redirect_url=redirect_url)
    return tolerant_jsonify({
        'casLogoutUrl': cas_logout_url,
        **current_user.to_api_json(),
    })


def _cas_client(target_url=None):
    cas_server = app.config['CAS_SERVER']
    # One (possible) advantage this has over "request.base_url" is that it embeds the configured SERVER_NAME.
    service_url = url_for('.cas_login', _external=True)
    if target_url:
        service_url = service_url + '?' + urlencode({'url': target_url})
    return cas.CASClientV3(server_url=cas_server, service_url=service_url)


def _is_authorized_user(user):
    return user.is_admin or len(user.department_memberships) > 0 if user else False


def _is_safe_url(target):
    ref_url = urlparse(request.host_url)
    test_url = urlparse(urljoin(request.host_url, target))
    return test_url.scheme in ('http', 'https') and ref_url.netloc == test_url.netloc


def _login(user):
    session = login_user(UserSession(user.id))
    if session:
        User.record_login(user.id)
    return session
