import _ from 'lodash'
import {deleteContact, getDepartment, updateContact, updateDepartmentNote} from '@/api/departments'
import Vue from 'vue'

const $_refresh = (commit, {departmentId, termId}) => {
  return new Promise<void>(resolve => {
    getDepartment(departmentId, termId).then((department: any) => {
      commit('reset', {department, termId})
      return resolve(department)
    })
  })
}

const state = {
  contacts: [],
  departmentId: undefined,
  disableControls: false,
  note: undefined,
  selectedTerm: undefined
}

const getters = {
  contacts: (state: any): any[] => state.contacts,
  departmentId: (state: any): number => state.departmentId,
  disableControls: (state: any): boolean => state.disableControls,
  note: (state: any): string => state.note,
  selectedTerm: (state: any): any => state.selectedTerm
}

const actions = {
  deleteContact: ({commit, state}, userId: number) => {
    commit('setDisableControls', true)
    return deleteContact(state.departmentId, userId).then(() => {
      $_refresh(commit, {departmentId: state.departmentId, termId: state.selectedTerm.id})
    })
  },
  init: ({commit}, {departmentId: departmentId, termId: termId}) => {
    return new Promise<void>(resolve => {
      $_refresh(commit, {departmentId, termId}).then(department => resolve(department))
    })
  },
  updateNote: ({commit, state}, note: string) => {
    commit('setDisableControls', true)
    return new Promise<void>(resolve => {
      updateDepartmentNote(state.departmentId, note, state.selectedTerm.id).then(() => {
        $_refresh(commit, {departmentId: state.departmentId, termId: state.selectedTerm.id}).then(dept => resolve(dept))
      })
    })
  },
  updateContact: ({commit, state}, contact: any) => {
    commit('setDisableControls', true)
    return new Promise<void>(resolve => {
      updateContact(state.departmentId, contact).then(() => {
        $_refresh(commit, {departmentId: state.departmentId, termId: state.selectedTerm.id}).then(dept => resolve(dept))
      })
    })
  }
}

const mutations = {
  reset: (state: any, {department, termId}) => {
    if (department) {
      state.contacts = department.contacts
      state.departmentId = department.id
      state.note = _.get(department.notes, [termId, 'note'])
    }
    state.selectedTerm = _.find(Vue.prototype.$config.availableTerms, {'id': termId})
    state.disableControls = false
  },
  setDisableControls: (state: any, disable: boolean) => state.disableControls = disable
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}