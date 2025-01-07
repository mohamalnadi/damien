import {get, includes} from 'lodash'
import router from './router'
import {useContextStore} from '@/stores/context'

export function appErrorHandler(error: any, vm: any, info: string) {
  const message = get(error, 'message') || info
  const stacktrace = get(error, 'stack', null)
  // eslint-disable-next-line no-console
  console.log(`\n${message}\n${stacktrace}\n`)
}

export function axiosErrorHandler(error, vm: any, info?: string) {
  const errorStatus = get(error, 'response.status') || info
  const currentUser = useContextStore().currentUser
  if (currentUser.isAuthenticated) {
    if (errorStatus === 404) {
      router.push({path: '/404'})
    } else if (errorStatus >= 400) {
      const message = get(error, 'response.data.message') || error.message
      // eslint-disable-next-line no-console
      console.error(message)
      router.push({
        path: '/error',
        query: {
          m: message
        }
      })
    } else if (errorStatus === 400) {
      // eslint-disable-next-line no-console
      console.error(error)
    }
  } else {
    router.push({
      path: '/start',
      query: {
        m: 'Your session has expired'
      }
    })
  }
}

export function initializeAxios(axios: any) {
  axios.defaults.withCredentials = true
  axios.interceptors.response.use(
    (response: any) => response,
    (error: any) => {
      const errorStatus = get(error, 'response.status')
      if (includes([401, 403], errorStatus)) {
        // Refresh user in case his/her session expired.
        const apiBaseUrl = import.meta.env.VITE_APP_API_BASE_URL
        return axios.get(`${apiBaseUrl}/api/profile/my`).then((response: any) => {
          useContextStore().setCurrentUser(response.data)
          axiosErrorHandler(error, axios)
          return Promise.reject(error)
        })
      } else {
        const errorUrl = get(error, 'response.config.url')
        // 400 and 404 from the section or department evaluations API should be handled by the individual component.
        if (!(errorUrl && (errorUrl.includes('/api/section') || (errorUrl.includes('/api/department') && errorUrl.includes('/evaluations'))))) {
          axiosErrorHandler(error, axios)
        }
        return Promise.reject(error)
      }
    })
}
