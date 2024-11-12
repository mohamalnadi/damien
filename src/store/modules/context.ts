import {find} from 'lodash'
import {getServiceAnnouncement} from '@/api/config'
import {putFocusNextTick} from '@/lib/utils'

const state = {
  config: {

  },
  currentUser: {
    isAdmin: false,
    isAuthenticated: false
  },
  isSelectedTermLocked: false,
  loading: undefined,
  screenReaderAlert: undefined,
  selectedTermId: undefined,
  selectedTermName: undefined,
  serviceAnnouncement: undefined,
  snackbar: {
    color: 'primary',
    text: undefined,
    timeout: 8000
  },
  snackbarShow: false
}

const getters = {
  config: (state: any): boolean => state.config,
  currentUser: (state: any): boolean => state.currentUser,
  isSelectedTermLocked: (state: any): boolean => state.isSelectedTermLocked,
  loading: (state: any): boolean => state.loading,
  screenReaderAlert: (state: any): string => state.screenReaderAlert,
  selectedTermId: (state: any): string => state.selectedTermId,
  selectedTermName: (state: any): string => state.selectedTermName,
  serviceAnnouncement: (state: any): string => state.serviceAnnouncement,
  snackbar: (state: any): any => state.snackbar,
  snackbarShow: (state: any): boolean => state.snackbarShow,
}

const mutations = {
  loadingComplete: (state: any, {pageTitle, alert}) => {
    document.title = `${pageTitle || 'UC Berkeley'} | Course Evaluations`
    state.loading = false
    if (alert) {
      state.screenReaderAlert = alert
    } else if (pageTitle) {
      state.screenReaderAlert = `${pageTitle} page is ready`
    }
    putFocusNextTick('page-title')
  },
  loadingStart: (state: any) => (state.loading = true),
  setConfig: (state: any, config: any) => state.config = config,
  setCurrentUser: (state: any, currentUser: any) => state.currentUser = currentUser,
  setIsSelectedTermLocked: (state: any, isLocked: boolean) => (state.isSelectedTermLocked = isLocked),
  setScreenReaderAlert: (state: any, alert: string) => (state.screenReaderAlert = alert),
  setSelectedTerm: (state: any, termId: string) => {
    return new Promise<void>(resolve => {
      const term = find(state.config.availableTerms, {'id': termId || state.config.currentTermId})
      if (term) {
        state.selectedTermId = term.id
        state.selectedTermName = term.name
        resolve()
      }
    })
  },
  setServiceAnnouncement: (state: any, data: any) => state.serviceAnnouncement = data,
  snackbarClose: (state: any) => {
    state.snackbarShow = false
    state.snackbar.text = undefined
    state.screenReaderAlert = 'Message closed'
  },
  snackbarOpen: (state: any, {text, color}) => {
    state.snackbar.text = text
    state.snackbar.color = color || 'secondary'
    state.snackbarShow = true
  },
  snackbarReportError: (state: any, text: string) => {
    state.snackbar.text = text
    state.snackbar.color = 'error'
    state.snackbarShow = true
  },
  updateConfig: (state: any, {key, value}) => state.config[key] = value
}

const actions = {
  alertScreenReader: ({ commit }, alert: string) => commit('setScreenReaderAlert', alert),
  loadingComplete: ({ commit }, {pageTitle, alert}) => commit('loadingComplete', {pageTitle, alert}),
  loadingStart: ({ commit }) => {
    commit('loadingStart')
    getServiceAnnouncement().then(data => {
      commit('setServiceAnnouncement', data)
    })
  },
  selectTerm: ({ commit }, termId) => commit('setSelectedTerm', termId),
  setConfig: ({ commit }, config) => commit('setConfig', config),
  setCurrentUser: ({ commit }, currentUser) => commit('setCurrentUser', currentUser),
  setIsSelectedTermLocked: ({ commit }, isLocked: boolean) => commit('setIsSelectedTermLocked', isLocked),
  snackbarClose: ({ commit }) => commit('snackbarClose'),
  snackbarOpen: ({ commit }, {text, color}) => commit('snackbarOpen', {text, color}),
  snackbarReportError: ({ commit }, text: string) => commit('snackbarReportError', text),
  updateConfig: ({ commit }, {key, value}) => commit('updateConfig', {key, value})
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
