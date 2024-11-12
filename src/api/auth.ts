import axios from 'axios'
import {getApiBaseUrl} from '@/api/api-utils'
import {useContextStore} from '@/stores/context'

export function devAuthLogIn(uid: string, password: string) {
  return axios
      .post(`${getApiBaseUrl()}/api/auth/dev_auth_login`, {uid, password})
        .then(data => {
          const contextStore = useContextStore()
          contextStore.setCurrentUser(data)
          return contextStore.currentUser
        }, error => error)
}

export function getCasLoginURL() {
  return axios.get(`${getApiBaseUrl()}/api/auth/cas_login_url`)
}

export function getCasLogoutUrl() {
  return axios.get(`${getApiBaseUrl()}/api/auth/logout`)
}
