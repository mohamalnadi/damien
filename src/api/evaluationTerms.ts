import axios from 'axios'
import {getApiBaseUrl} from '@/api/api-utils'

export function getEvaluationTerm(termId: string) {
  return axios.get(`${getApiBaseUrl()}/api/evaluation_term/${termId}`)
    .then(response => response.data)
}

export function lockEvaluationTerm(termId: string) {
  return axios.post(`${getApiBaseUrl()}/api/evaluation_term/lock`, {termId})
    .then(response => response.data)
}

export function unlockEvaluationTerm(termId: string) {
  return axios.post(`${getApiBaseUrl()}/api/evaluation_term/unlock`, {termId})
    .then(response => response.data)
}
