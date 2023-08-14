/**
 * Copyright ©2023. The Regents of the University of California (Regents). All Rights Reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its documentation
 * for educational, research, and not-for-profit purposes, without fee and without a
 * signed licensing agreement, is hereby granted, provided that the above copyright
 * notice, this paragraph and the following two paragraphs appear in all copies, TRUE),
 * modifications, and distributions.
 *
 * Contact The Office of Technology Licensing, UC Berkeley, 2150 Shattuck Avenue, TRUE),
 * Suite 510, Berkeley, CA 94720-1620, (510) 643-7201, otl@berkeley.edu, TRUE),
 * http://ipira.berkeley.edu/industry-info for commercial licensing opportunities.
 *
 * IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, TRUE),
 * INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF
 * THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS HAS BEEN ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
 * SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED
 * "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, TRUE),
 * ENHANCEMENTS, OR MODIFICATIONS.
 */

BEGIN;

TRUNCATE TABLE department_catalog_listings;
TRUNCATE TABLE department_forms CASCADE;
TRUNCATE TABLE departments CASCADE;
TRUNCATE TABLE evaluation_types CASCADE;

INSERT INTO departments (dept_name, is_enrolled) VALUES
  ('African American Studies', TRUE),
  ('Agricultural and Resource Economics', TRUE),
  ('American Studies', TRUE),
  ('Ancient Greek and Roman Studies', TRUE),
  ('Ancient History and Mediterranean Archaeology', FALSE),
  ('Anthropology', TRUE),
  ('Architecture', TRUE),
  ('Art Practice', TRUE),
  ('Astronomy', TRUE),
  ('Bioengineering', TRUE),
  ('CalTeach', TRUE),
  ('Celtic Studies', TRUE),
  ('Chemical and Biomolecular Engineering', TRUE),
  ('Chemistry', TRUE),
  ('City and Regional Planning', TRUE),
  ('Civil and Environmental Engineering', TRUE),
  ('College Writing', TRUE),
  ('Comparative Literature', TRUE),
  ('Computational Biology', TRUE),
  ('Computing, Data Science, and Society', TRUE),
  ('Critical Theory', FALSE),
  ('Demography', TRUE),
  ('Digital Humanities', TRUE),
  ('Earth and Planetary Science', TRUE),
  ('East Asian Languages and Cultures', TRUE),
  ('Economics', TRUE),
  ('Education', TRUE),
  ('Electrical Engineering and Computer Sciences', TRUE),
  ('Energy and Resources Group', TRUE),
  ('Engineering', TRUE),
  ('English', TRUE),
  ('Environmental Design', TRUE),
  ('Environmental Science, Policy and Management', TRUE),
  ('Ethnic Studies', TRUE),
  ('Film and Media', TRUE),
  ('French', TRUE),
  ('Freshman and Sophomore Seminars', TRUE),
  ('Gender and Women''s Studies', TRUE),
  ('Geography', TRUE),
  ('German', TRUE),
  ('Global Metropolitan Studies', TRUE),
  ('Goldman School of Public Policy', FALSE),
  ('Graduate Division', TRUE),
  ('Haas School of Business', FALSE),
  ('Helen Wills Neuroscience', TRUE),
  ('History', TRUE),
  ('History of Art', TRUE),
  ('Industrial Engineering and Operations Research', TRUE),
  ('Information', TRUE),
  ('Integrative Biology', TRUE),
  ('Interdisciplinary Studies Field', TRUE),
  ('International and Area Studies', TRUE),
  ('Italian Studies', TRUE),
  ('Jewish Studies', TRUE),
  ('Journalism', TRUE),
  ('L&S Arts and Humanities', TRUE),
  ('Landscape Architecture and Environmental Planning', TRUE),
  ('Law', FALSE),
  ('Legal Studies', TRUE),
  ('Linguistics', TRUE),
  ('Materials Science and Engineering', TRUE),
  ('Mathematics', TRUE),
  ('Mechanical Engineering', TRUE),
  ('Media Studies', TRUE),
  ('Medieval Studies', FALSE),
  ('Middle Eastern Languages and Cultures', TRUE),
  ('Military Affairs', TRUE),
  ('Molecular and Cell Biology', TRUE),
  ('Music', TRUE),
  ('Nanosciences and Nanoengineering Institute', FALSE),
  ('Natural Resources', FALSE),
  ('New Media', TRUE),
  ('Nuclear Engineering', TRUE),
  ('Nutritional Sciences and Toxicology', TRUE),
  ('Optometry', FALSE),
  ('Philosophy', TRUE),
  ('Physical Education', TRUE),
  ('Physics', TRUE),
  ('Plant and Microbial Biology', TRUE),
  ('Political Science', TRUE),
  ('Psychology', TRUE),
  ('Public Health', TRUE),
  ('QB3 Institute', FALSE),
  ('Real Estate Development and Design', TRUE),
  ('Rhetoric', TRUE),
  ('Scandinavian', TRUE),
  ('Science, Technology, Medicine and Society', FALSE),
  ('Slavic Languages and Literatures', TRUE),
  ('Social Welfare', TRUE),
  ('Sociology', TRUE),
  ('South and Southeast Asian Studies', TRUE),
  ('Spanish and Portuguese', TRUE),
  ('Statistics', TRUE),
  ('Summer Sessions Online', TRUE),
  ('Theater, Dance and Performance Studies', TRUE),
  ('Undergraduate and Interdisciplinary Studies', TRUE),
  ('Computational Precision Health', TRUE);

CREATE TEMP TABLE listings (
  dept_name VARCHAR,
  subject_area VARCHAR,
  catalog_id VARCHAR,
  default_form VARCHAR,
  start_term_id VARCHAR,
  end_term_id VARCHAR
);

-- In most cases the default form name is the same as the course-code subject area. However, there are cases where it
-- differs, either because of catalog-id-specific mappings, or because the default form uses legacy punctuation
-- (e.g. "L & S") which no longer appears in our data sources.

INSERT INTO listings (dept_name, subject_area, catalog_id, default_form, start_term_id, end_term_id) VALUES
  ('African American Studies', 'AFRICAM', NULL, 'AFRICAM', NULL, NULL),
  ('Agricultural and Resource Economics', 'ARESEC', NULL, 'A_RESEC', NULL, NULL),
  ('Agricultural and Resource Economics', 'ENVECON', NULL, 'ENVECON', NULL, NULL),
  ('American Studies', 'AMERSTD', NULL, 'AMERSTD', NULL, NULL),
  ('Ancient Greek and Roman Studies', 'AGRS', NULL, 'AGRS', NULL, NULL),
  ('Ancient Greek and Roman Studies', 'CLASSIC', NULL, 'CLASSIC', NULL, NULL),
  ('Ancient Greek and Roman Studies', 'GREEK', NULL, 'GREEK', NULL, NULL),
  ('Ancient Greek and Roman Studies', 'LATIN', NULL, 'LATIN', NULL, NULL),
  ('Ancient History and Mediterranean Archaeology', 'AHMA', NULL, 'AHMA', NULL, NULL),
  ('Anthropology', 'ANTHRO', NULL, 'ANTHRO', NULL, NULL),
  ('Anthropology', 'FOLKLOR', NULL, 'FOLKLOR', NULL, NULL),
  ('Architecture', 'ARCH', NULL, 'ARCH', NULL, NULL),
  ('Architecture', 'ENVDES', NULL, 'ENVDES', NULL, '2228'),
  ('Architecture', 'VISSTD', NULL, 'VISSTD', NULL, NULL),
  ('Art Practice', 'ART', NULL, 'ART', NULL, NULL),
  ('Astronomy', 'ASTRON', NULL, 'ASTRON', NULL, NULL),
  ('Bioengineering', 'BIOENG', NULL, 'BIO ENG', NULL, NULL),
  ('CalTeach', 'CALTEACH', NULL, 'CALTEACH', NULL, NULL),
  ('CalTeach', 'EDSTEM', NULL, 'CALTEACH', NULL, NULL),
  ('CalTeach', 'EDUC', '130', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'EDUC', '131AC', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'HISTORY', '138T', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'HISTORY', '180T', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'HISTORY', '182AT', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'UGIS', '82', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'UGIS', '187', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'UGIS', '188', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'UGIS', '189', 'CALTEACH', NULL, NULL),
  ('CalTeach', 'UGIS', '303', 'CALTEACH', NULL, NULL),
  ('Celtic Studies', 'CELTIC', NULL, 'CELTIC', NULL, NULL),
  ('Chemical and Biomolecular Engineering', 'CHMENG', NULL, 'CHM ENG', NULL, NULL),
  ('Chemistry', 'CHEM', NULL, 'CHEM', NULL, NULL),
  ('City and Regional Planning', 'CYPLAN', NULL, 'CY PLAN', NULL, NULL),
  ('Civil and Environmental Engineering', 'CIVENG', NULL, 'CIV ENG', NULL, NULL),
  ('Civil and Environmental Engineering', 'DEVENG', NULL, 'DEV ENG', NULL, NULL),
  ('College Writing', 'COLWRIT', NULL, 'COLWRIT', NULL, NULL),
  ('Comparative Literature', 'COMLIT', NULL, 'COM LIT', NULL, NULL),
  ('Computational Biology', 'CMPBIO', NULL, 'CMPBIO', NULL, NULL),
  ('Computing, Data Science, and Society', 'DATA', NULL, 'DATA', NULL, NULL),
  ('Critical Theory', 'CRITTH', NULL, 'CRITTH', NULL, NULL),
  ('Demography', 'DEMOG', NULL, 'DEMOG', NULL, NULL),
  ('Digital Humanities', 'DIGHUM', NULL, 'DIGHUM', NULL, NULL),
  ('Earth and Planetary Science', 'EPS', NULL, 'EPS', NULL, NULL),
  ('East Asian Languages and Cultures', 'ALTAIC', NULL, 'ALTAIC', NULL, NULL),
  ('East Asian Languages and Cultures', 'ASIANST', NULL, 'ASIANST', NULL, NULL),
  ('East Asian Languages and Cultures', 'BUDDSTD', NULL, 'BUDDSTD', NULL, NULL),
  ('East Asian Languages and Cultures', 'CHINESE', NULL, 'CHINESE', NULL, NULL),
  ('East Asian Languages and Cultures', 'EALANG', NULL, 'EALANG', NULL, NULL),
  ('East Asian Languages and Cultures', 'JAPAN', NULL, 'JAPAN', NULL, NULL),
  ('East Asian Languages and Cultures', 'KOREAN', NULL, 'KOREAN', NULL, NULL),
  ('East Asian Languages and Cultures', 'MONGOLN', NULL, 'MONGOLN', NULL, NULL),
  ('East Asian Languages and Cultures', 'TIBETAN', NULL, 'TIBETAN', NULL, NULL),
  ('Economics', 'ECON', NULL, 'ECON', NULL, NULL),
  ('Education', 'EDUC', NULL, 'EDUC', NULL, NULL),
  ('Education', 'SCMATHE', NULL, 'SCMATHE', NULL, NULL),
  ('Electrical Engineering and Computer Sciences', 'COMPSCI', NULL, 'COMPSCI', NULL, NULL),
  ('Electrical Engineering and Computer Sciences', 'EECS', NULL, 'EECS', NULL, NULL),
  ('Electrical Engineering and Computer Sciences', 'ELENG', NULL, 'EL ENG', NULL, NULL),
  ('Energy and Resources Group', 'ENERES', NULL, 'ENE_RES', NULL, NULL),
  ('Engineering', 'AST', NULL, 'AST', NULL, NULL),
  ('Engineering', 'DESINV', NULL, 'DES INV', NULL, NULL),
  ('Engineering', 'ENGIN', NULL, 'ENGIN', NULL, NULL),
  ('Engineering', 'NSE', NULL, 'NSE', NULL, NULL),
  ('English', 'CRWRIT', NULL, 'CRWRIT', NULL, NULL),
  ('English', 'ENGLISH', NULL, 'ENGLISH', NULL, NULL),
  ('Environmental Design', 'ENVDES', NULL, 'ENVDES', '2232', NULL),
  ('Environmental Science, Policy and Management', 'ENVSCI', NULL, 'ENVSCI', NULL, NULL),
  ('Environmental Science, Policy and Management', 'ESPM', NULL, 'ESPM', NULL, NULL),
  ('Ethnic Studies', 'ASAMST', NULL, 'ASAMST', NULL, NULL),
  ('Ethnic Studies', 'CHICANO', NULL, 'CHICANO', NULL, NULL),
  ('Ethnic Studies', 'ETHGRP', NULL, 'ETH GRP', NULL, NULL),
  ('Ethnic Studies', 'ETHSTD', NULL, 'ETH STD', NULL, NULL),
  ('Ethnic Studies', 'NATAMST', NULL, 'NATAMST', NULL, NULL),
  ('Film and Media', 'FILM', NULL, 'FILM', NULL, NULL),
  ('French', 'FRENCH', NULL, 'FRENCH', NULL, NULL),
  ('Freshman and Sophomore Seminars', '', '(39|24|84)[A-Z]*', 'FSSEM', NULL, NULL),
  ('Freshman and Sophomore Seminars', 'MCELLBI', '90[A-Z]', 'FSSEM', NULL, NULL),
  ('Freshman and Sophomore Seminars', 'NATAMST', '90[A-Z]', 'FSSEM', NULL, NULL),
  ('Gender and Women''s Studies', 'GWS', NULL, 'GWS', NULL, NULL),
  ('Gender and Women''s Studies', 'LGBT', NULL, 'LGBT', NULL, NULL),
  ('Geography', 'GEOG', NULL, 'GEOG', NULL, NULL),
  ('German', 'AFRKANS', NULL, 'AFRKANS', NULL, NULL),
  ('German', 'DUTCH', NULL, 'DUTCH', NULL, NULL),
  ('German', 'GERMAN', NULL, 'GERMAN', NULL, NULL),
  ('German', 'YIDDISH', NULL, 'YIDDISH', NULL, NULL),
  ('Global Metropolitan Studies', 'GMS', NULL, 'GMS', NULL, NULL),
  ('Goldman School of Public Policy', 'PUBPOL', NULL, 'PUBPOL', NULL, NULL),
  ('Graduate Division', 'CMPBIO', NULL, 'CMPBIO', NULL, NULL),
  ('Graduate Division', 'GSPDP', NULL, 'GSPDP', NULL, NULL),
  ('Graduate Division', 'LANPRO', NULL, 'LAN PRO', NULL, NULL),
  ('Haas School of Business', 'BUSADM', NULL, 'BUSADM', NULL, NULL),
  ('Haas School of Business', 'EWMBA', NULL, 'EWMBA', NULL, NULL),
  ('Haas School of Business', 'MBA', NULL, 'MBA', NULL, NULL),
  ('Haas School of Business', 'MFE', NULL, 'MFE', NULL, NULL),
  ('Haas School of Business', 'PHDBA', NULL, 'PHDBA', NULL, NULL),
  ('Haas School of Business', 'UGBA', NULL, 'UGBA', NULL, NULL),
  ('Haas School of Business', 'XMBA', NULL, 'XMBA', NULL, NULL),
  ('Helen Wills Neuroscience', 'NEUROSC', NULL, 'NEUROSC', NULL, NULL),
  ('History of Art', 'HISTART', NULL, 'HISTART', NULL, NULL),
  ('History', 'HISTORY', NULL, 'HISTORY', NULL, NULL),
  ('Industrial Engineering and Operations Research', 'INDENG', NULL, 'IND ENG', NULL, NULL),
  ('Information', 'CYBER', NULL, 'CYBER', NULL, NULL),
  ('Information', 'DATASCI', NULL, 'DATASCI', NULL, NULL),
  ('Information', 'INFO', NULL, 'INFO', NULL, NULL),
  ('Integrative Biology', 'BIOLOGY', '1B', 'INTEGBI', NULL, NULL),
  ('Integrative Biology', 'BIOLOGY', '1BL', 'INTEGBI', NULL, NULL),
  ('Integrative Biology', 'INTEGBI', NULL, 'INTEGBI', NULL, NULL),
  ('Interdisciplinary Studies Field', 'ISF', NULL, 'ISF', NULL, NULL),
  ('International and Area Studies', 'COGSCI', NULL, 'COGSCI', NULL, NULL),
  ('International and Area Studies', 'DEVSTD', NULL, 'DEVSTD', NULL, NULL),
  ('International and Area Studies', 'GLOBAL', NULL, 'GLOBAL', NULL, NULL),
  ('International and Area Studies', 'GPP', NULL, 'GPP', NULL, NULL),
  ('International and Area Studies', 'IAS', NULL, 'IAS', NULL, NULL),
  ('International and Area Studies', 'LATAMST', NULL, 'LATAMST', NULL, NULL),
  ('International and Area Studies', 'MESTU', NULL, 'MESTU', NULL, NULL),
  ('International and Area Studies', 'PACS', NULL, 'PACS', NULL, NULL),
  ('International and Area Studies', 'POLECON', NULL, 'POLECON', NULL, NULL),
  ('Italian Studies', 'ITALIAN', NULL, 'ITALIAN', NULL, NULL),
  ('Jewish Studies', 'JEWISH', NULL, 'JEWISH', NULL, NULL),
  ('Journalism', 'JOURN', NULL, 'JOURN', NULL, NULL),
  ('L&S Arts and Humanities', 'HUM', NULL, 'HUM', NULL, NULL),
  ('Landscape Architecture and Environmental Planning', 'LDARCH', NULL, 'LDARCH', NULL, NULL),
  ('Law', 'LAW', NULL, 'LAW', NULL, NULL),
  ('Legal Studies', 'LEGALST', NULL, 'LEGALST', NULL, NULL),
  ('Linguistics', 'LINGUIS', NULL, 'LINGUIS', NULL, NULL),
  ('Materials Science and Engineering', 'MATSCI', NULL, 'MAT SCI', NULL, NULL),
  ('Mathematics', 'MATH', NULL, 'MATH', NULL, NULL),
  ('Mechanical Engineering', 'MECENG', NULL, 'MEC ENG', NULL, NULL),
  ('Media Studies', 'MEDIAST', NULL, 'MEDIAST', NULL, NULL),
  ('Medieval Studies', 'MEDST', NULL, 'MEDST', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'ARABIC', NULL, 'ARABIC', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'CUNEIF', NULL, 'CUNEIF', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'EGYPT', NULL, 'EGYPT', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'HEBREW', NULL, 'HEBREW', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'IRANIAN', NULL, 'IRANIAN', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'MELC', NULL, 'MELC', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'NESTUD', NULL, 'NE STUD', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'PERSIAN', NULL, 'PERSIAN', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'SEMITIC', NULL, 'SEMITIC', NULL, NULL),
  ('Middle Eastern Languages and Cultures', 'TURKISH', NULL, 'TURKISH', NULL, NULL),
  ('Military Affairs', 'AEROSPC', NULL, 'AEROSPC', NULL, NULL),
  ('Military Affairs', 'MILAFF', NULL, 'MIL AFF', NULL, NULL),
  ('Military Affairs', 'MILSCI', NULL, 'MIL SCI', NULL, NULL),
  ('Military Affairs', 'NAVSCI', NULL, 'NAV SCI', NULL, NULL),
  ('Molecular and Cell Biology', 'BIOLOGY', '1A', 'MCELLBI', NULL, NULL),
  ('Molecular and Cell Biology', 'BIOLOGY', '1AL', 'MCELLBI', NULL, NULL),
  ('Molecular and Cell Biology', 'MCELLBI', NULL, 'MCELLBI', NULL, NULL),
  ('Music', 'MUSIC', NULL, 'MUSIC', NULL, NULL),
  ('Natural Resources', 'DEVP', NULL, 'DEVP', NULL, NULL),
  ('Natural Resources', 'NATRES', NULL, 'NAT RES', NULL, NULL),
  ('New Media', 'NWMEDIA', NULL, 'NWMEDIA', NULL, NULL),
  ('Nuclear Engineering', 'NUCENG', NULL, 'NUC ENG', NULL, NULL),
  ('Nutritional Sciences and Toxicology', 'NUSCTX', NULL, 'NUSCTX', NULL, NULL),
  ('Optometry', 'OPTOM', NULL, 'OPTOM', NULL, NULL),
  ('Optometry', 'VISSCI', NULL, 'VISSCI', NULL, NULL),
  ('Philosophy', 'PHILOS', NULL, 'PHILOS', NULL, NULL),
  ('Physical Education', 'PHYSED', NULL, 'PHYS ED', NULL, NULL),
  ('Physics', 'PHYSICS', NULL, 'PHYSICS', NULL, NULL),
  ('Plant and Microbial Biology', 'AGRCHM', NULL, 'AGRCHM', NULL, NULL),
  ('Plant and Microbial Biology', 'PLANTBI', NULL, 'PLANTBI', NULL, NULL),
  ('Political Science', 'POLSCI', NULL, 'POL SCI', NULL, NULL),
  ('Psychology', 'PSYCH', NULL, 'PSYCH', NULL, NULL),
  ('Public Health', 'CMPBIO', '294', 'PB HLTH', NULL, NULL),
  ('Public Health', 'HMEDSCI', NULL, 'HMEDSCI', NULL, NULL),
  ('Public Health', 'PBHLTH', NULL, 'PB HLTH', NULL, NULL),
  ('QB3', 'BIOPHY', NULL, 'BIOPHY', NULL, NULL),
  ('Real Estate Development and Design', 'LDARCH', '254', 'RDEV', NULL, NULL),
  ('Real Estate Development and Design', 'RDEV', NULL, 'RDEV', NULL, NULL),
  ('Rhetoric', 'RHETOR', NULL, 'RHETOR', NULL, NULL),
  ('Scandinavian', 'DANISH', NULL, 'DANISH', NULL, NULL),
  ('Scandinavian', 'FINNISH', NULL, 'FINNISH', NULL, NULL),
  ('Scandinavian', 'ICELAND', NULL, 'ICELAND', NULL, NULL),
  ('Scandinavian', 'NORWEGN', NULL, 'NORWEGN', NULL, NULL),
  ('Scandinavian', 'SCANDIN', NULL, 'SCANDIN', NULL, NULL),
  ('Scandinavian', 'SWEDISH', NULL, 'SWEDISH', NULL, NULL),
  ('Science, Technology, Medicine and Society', 'STS', NULL, 'STS', NULL, NULL),
  ('Slavic Languages and Literatures', 'ARMENI', NULL, 'ARMENI', NULL, NULL),
  ('Slavic Languages and Literatures', 'BOSCRSR', NULL, 'BOSCRSR', NULL, NULL),
  ('Slavic Languages and Literatures', 'BULGARI', NULL, 'BULGARI', NULL, NULL),
  ('Slavic Languages and Literatures', 'CZECH', NULL, 'CZECH', NULL, NULL),
  ('Slavic Languages and Literatures', 'EAEURST', NULL, 'EAEURST', NULL, NULL),
  ('Slavic Languages and Literatures', 'EURAST', NULL, 'EURA ST', NULL, NULL),
  ('Slavic Languages and Literatures', 'EUST', NULL, 'EUST', NULL, NULL),
  ('Slavic Languages and Literatures', 'HUNGARI', NULL, 'HUNGARI', NULL, NULL),
  ('Slavic Languages and Literatures', 'POLISH', NULL, 'POLISH', NULL, NULL),
  ('Slavic Languages and Literatures', 'ROMANI', NULL, 'ROMANI', NULL, NULL),
  ('Slavic Languages and Literatures', 'RUSSIAN', NULL, 'RUSSIAN', NULL, NULL),
  ('Slavic Languages and Literatures', 'SLAVIC', NULL, 'SLAVIC', NULL, NULL),
  ('Slavic Languages and Literatures', 'UKRAINI', NULL, 'UKRAINI', NULL, NULL),
  ('Social Welfare', 'SOCWEL', NULL, 'SOC WEL', NULL, NULL),
  ('Sociology', 'SOCIOL', NULL, 'SOCIOL', NULL, NULL),
  ('South and Southeast Asian Studies', 'BANGLA', NULL, 'BANGLA', NULL, NULL),
  ('South and Southeast Asian Studies', 'BURMESE', NULL, 'BURMESE', NULL, NULL),
  ('South and Southeast Asian Studies', 'FILIPN', NULL, 'FILIPN', NULL, NULL),
  ('South and Southeast Asian Studies', 'HINURD', NULL, 'HINURD', NULL, NULL),
  ('South and Southeast Asian Studies', 'HINDI', NULL, 'HINDI', NULL, NULL),
  ('South and Southeast Asian Studies', 'INDONES', NULL, 'INDONES', NULL, NULL),
  ('South and Southeast Asian Studies', 'KHMER', NULL, 'KHMER', NULL, NULL),
  ('South and Southeast Asian Studies', 'MALAYI', NULL, 'MALAYI', NULL, NULL),
  ('South and Southeast Asian Studies', 'PUNJABI', NULL, 'PUNJABI', NULL, NULL),
  ('South and Southeast Asian Studies', 'SASIAN', NULL, 'SASIAN', NULL, NULL),
  ('South and Southeast Asian Studies', 'SSEASN', NULL, 'S_SEASN', NULL, NULL),
  ('South and Southeast Asian Studies', 'SANSKR', NULL, 'SANSKR', NULL, NULL),
  ('South and Southeast Asian Studies', 'SEASIAN', NULL, 'SEASIAN', NULL, NULL),
  ('South and Southeast Asian Studies', 'TAGALG', NULL, 'TAGALG', NULL, NULL),
  ('South and Southeast Asian Studies', 'TAMIL', NULL, 'TAMIL', NULL, NULL),
  ('South and Southeast Asian Studies', 'TELUGU', NULL, 'TELUGU', NULL, NULL),
  ('South and Southeast Asian Studies', 'THAI', NULL, 'THAI', NULL, NULL),
  ('South and Southeast Asian Studies', 'URDU', NULL, 'URDU', NULL, NULL),
  ('South and Southeast Asian Studies', 'VIETNMS', NULL, 'VIETNMS', NULL, NULL),
  ('Spanish and Portuguese', 'CATALAN', NULL, 'SPANISH', NULL, NULL),
  ('Spanish and Portuguese', 'ILA', NULL, 'SPANISH', NULL, NULL),
  ('Spanish and Portuguese', 'PORTUG', NULL, 'SPANISH', NULL, NULL),
  ('Spanish and Portuguese', 'SPANISH', NULL, 'SPANISH', NULL, NULL),
  ('Statistics', 'STAT', NULL, 'STAT', NULL, NULL),
  ('Summer Sessions Online', '', '[^[A-Z0-9]*]', NULL, '2235', NULL),
  ('Theater, Dance and Performance Studies', 'THEATER', NULL, 'THEATER', NULL, NULL),
  ('Undergraduate and Interdisciplinary Studies', 'BIC', NULL, 'BIC', NULL, NULL),
  ('Undergraduate and Interdisciplinary Studies', 'LS', NULL, 'L & S', NULL, NULL),
  ('Undergraduate and Interdisciplinary Studies', 'RELIGST', NULL, 'RELIGST', NULL, NULL),
  ('Undergraduate and Interdisciplinary Studies', 'UGIS', NULL, 'UGIS', NULL, NULL),
  ('Computational Precision Health', 'CPH', NULL, 'CPH', NULL, NULL);

INSERT INTO department_forms (name)
  SELECT DISTINCT default_form
  FROM listings
  WHERE default_form IS NOT NULL;

INSERT INTO department_forms (name, deleted_at) VALUES ('ANCIENT_HISTORY', now());

INSERT INTO department_catalog_listings
  (department_id, subject_area, catalog_id, default_form_id, custom_evaluation_types, start_term_id, end_term_id)
SELECT
  departments.id,
  listings.subject_area,
  listings.catalog_id,
  department_forms.id,
  CASE WHEN listings.subject_area = 'HISTORY' THEN TRUE ELSE FALSE END,
  start_term_id,
  end_term_id
FROM listings
  JOIN departments ON departments.dept_name = listings.dept_name
  LEFT JOIN department_forms ON department_forms.name = listings.default_form;

INSERT INTO evaluation_types (name)
VALUES
  ('F'), ('G'), ('1'), ('1A'), ('2'), ('2A'), ('3'), ('3A'), ('4'), ('4A'), ('LANG'), ('LECT'), ('SEMI'), ('WRIT');

DROP TABLE listings;

COMMIT;
