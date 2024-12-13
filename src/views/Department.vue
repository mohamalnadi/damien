<template>
  <div v-if="!contextStore.loading" class="page-margins">
    <PageHeader>
      <div class="align-center d-flex justify-space-between">
        <div v-if="get(department, 'deptName')">
          {{ department.deptName }}
          <span v-if="size(getCatalogListings(department))">({{ getCatalogListings(department).join(', ') }})</span>
          <span v-if="contextStore.selectedTermName" class="mr-2">&mdash;{{ contextStore.selectedTermName }}</span>
        </div>
      </div>
      <template #append>
        <TermSelect :after-select="refresh" :term-ids="get(department, 'enrolledTerms')" />
      </template>
    </PageHeader>
    <div v-if="!currentUser.isAdmin && currentUser.departments.length > 1" class="mb-2">
      <v-menu rounded="lg">
        <template #activator="{props: defineProps}">
          <v-btn
            :append-icon="mdiChevronDown"
            color="tertiary"
            text="Change Department"
            variant="flat"
            v-bind="defineProps"
          />
        </template>
        <v-list>
          <template
            v-for="option in sortBy(currentUser.departments, 'name')"
            :key="option.id"
          >
            <v-list-item
              v-if="option.id !== department.id"
              :id="`department-${option.id}-menu-item`"
              @click="() => refresh(option.id)"
            >
              <v-list-item-title>{{ option.name }}</v-list-item-title>
            </v-list-item>
          </template>
        </v-list>
      </v-menu>
    </div>
    <v-container class="mx-0 pb-2 pt-1 px-0" fluid>
      <v-row justify="start">
        <v-col cols="12" md="6">
          <div class="border-sm pa-3">
            <v-expansion-panels v-model="contactsPanel" flat>
              <v-expansion-panel class="bg-transparent">
                <template #default>
                  <div class="d-flex align-center flex-wrap justify-space-between">
                    <h2 class="ml-2">Department Contacts</h2>
                    <v-expansion-panel-title
                      class="pl-1 pr-2 py-0 w-fit-content"
                      hide-actions
                      @click="collapseAllContacts"
                    >
                      <template #default="{expanded}">
                        <span v-if="!expanded">
                          Expand
                          <v-icon
                            class="rotate-180"
                            :icon="mdiPlusBoxMultipleOutline"
                          />
                        </span>
                        <span v-if="expanded">
                          Collapse All
                          <v-icon class="rotate-180 ml-1" :icon="mdiMinusBoxMultipleOutline" />
                        </span>
                      </template>
                    </v-expansion-panel-title>
                  </div>
                  <v-expansion-panel-text>
                    <v-expansion-panels
                      v-model="contactDetailsPanel"
                      flat
                      focusable
                      hover
                      multiple
                      tile
                    >
                      <DepartmentContact
                        v-for="(contact, index) in contacts"
                        :key="contact.id"
                        :contact="contact"
                        :index="index"
                        :is-expanded="includes(contactDetailsPanel, index)"
                      />
                    </v-expansion-panels>
                  </v-expansion-panel-text>
                </template>
              </v-expansion-panel>
            </v-expansion-panels>
            <div v-if="contextStore.currentUser.isAdmin" class="pt-2">
              <v-btn
                v-if="!isCreatingNotification"
                id="open-notification-form-btn"
                class="ml-2 secondary text-capitalize"
                color="primary"
                :disabled="disableControls || isEmpty(contacts)"
                text="Send notification"
                @click="() => isCreatingNotification = true"
              />
              <NotificationForm
                v-if="isCreatingNotification"
                :after-send="afterSendNotification"
                class="bg-surface-light border-sm"
                :on-cancel="cancelSendNotification"
                :recipients="[notificationRecipients]"
              />
            </div>
            <div v-if="currentUser.isAdmin" class="pt-3">
              <v-btn
                v-if="!isAddingContact"
                id="add-dept-contact-btn"
                color="tertiary"
                :disabled="disableControls"
                :prepend-icon="mdiPlusThick"
                text="Add Contact"
                variant="text"
                @click="onClickAddContact"
              />
              <EditDepartmentContact
                v-if="isAddingContact"
                :id="`add-department-contact`"
                :after-save="afterSaveContact"
                :on-cancel="onCancelAddContact"
              />
            </div>
          </div>
        </v-col>
        <v-col cols="12" md="6">
          <div class="border-sm px-5 py-3">
            <DepartmentNote />
          </div>
        </v-col>
      </v-row>
    </v-container>
    <div class="border-sm mt-3 position-relative">
      <EvaluationTable />
    </div>
    <v-overlay :value="showTheOmenPoster" z-index="300">
      <v-card>
        <v-toolbar dark color="secondary" density="compact">
          <v-icon
            class="font-weight-bold pb-1 pl-0"
            :icon="mdiClose"
            @click="() => departmentStore.setShowTheOmenPoster(false)"
          />
        </v-toolbar>
        <v-card-text class="text-center py-2">
          <img
            alt="Movie poster of The Omen"
            class="omen-poster-img"
            src="@/assets/omen_poster.png"
          />
        </v-card-text>
      </v-card>
    </v-overlay>
  </div>
</template>

<script setup>
import DepartmentContact from '@/components/admin/DepartmentContact'
import DepartmentNote from '@/components/admin/DepartmentNote'
import EditDepartmentContact from '@/components/admin/EditDepartmentContact'
import EvaluationTable from '@/components/evaluation/EvaluationTable'
import NotificationForm from '@/components/admin/NotificationForm'
import PageHeader from '@/components/util/PageHeader'
import TermSelect from '@/components/util/TermSelect'
import {NUMBER_OF_THE_BEAST, useDepartmentStore} from '@/stores/department/department-edit-session'
import {alertScreenReader, getCatalogListings, putFocusNextTick} from '@/lib/utils'
import {computed, onMounted, ref, watch} from 'vue'
import {filter as _filter, get, includes, isEmpty, size, sortBy} from 'lodash'
import {mdiChevronDown, mdiClose, mdiMinusBoxMultipleOutline, mdiPlusBoxMultipleOutline, mdiPlusThick} from '@mdi/js'
import {storeToRefs} from 'pinia'
import {useContextStore} from '@/stores/context'
import {useRoute, useRouter} from 'vue-router'

const contextStore = useContextStore()
const contactDetailsPanel = ref([])
const contactsPanel = ref(undefined)
const currentUser = contextStore.currentUser
const departmentStore = useDepartmentStore()
const isAddingContact = ref(false)
const isCreatingNotification = ref(false)
const route = useRoute()
const router = useRouter()
const {contacts, department, disableControls, showTheOmenPoster} = storeToRefs(departmentStore)

const notificationRecipients = computed(() => {
  return {
    deptName: department.value.deptName,
    deptId: department.value.id,
    recipients: _filter(contacts.value, 'canReceiveCommunications')
  }
})

watch(isAddingContact, () => {
  departmentStore.setDisableControls(isAddingContact.value)
})

watch(isCreatingNotification, () => {
  departmentStore.setDisableControls(isCreatingNotification.value)
})

onMounted(() => refresh())

const afterSaveContact = () => {
  isAddingContact.value = false
  contactsPanel.value = 0
  alertScreenReader('Contact saved.')
  putFocusNextTick('add-dept-contact-btn')
}

const afterSendNotification = () => {
  isCreatingNotification.value = false
  contextStore.snackbarOpen('Notification sent.')
  putFocusNextTick('open-notification-form-btn')
}

const cancelSendNotification = () => {
  isCreatingNotification.value = false
  alertScreenReader('Canceled notification.')
  putFocusNextTick('open-notification-form-btn')
}

const collapseAllContacts = () => {
  if (contactsPanel.value === 0) {
    contactDetailsPanel.value = []
  }
}

const onCancelAddContact = () => {
  isAddingContact.value = false
  alertScreenReader('Canceled. Nothing saved.')
  putFocusNextTick('add-dept-contact-btn')
}

const onClickAddContact = () => {
  isAddingContact.value = true
  putFocusNextTick('person-lookup-input')
}

const refresh = departmentId => {
  contextStore.loadingStart()
  const id = departmentId || get(route, 'params.departmentId')
  router.push({path: `/department/${id}`, query: {term: contextStore.selectedTermId}})
  alertScreenReader(`Loading ${contextStore.selectedTermName}`)
  departmentStore.init(id).then(department => {
    departmentStore.setShowTheOmenPoster(route.query.n === NUMBER_OF_THE_BEAST)
    contextStore.loadingComplete(`${department.deptName} ${contextStore.selectedTermName}`)
  })
}
</script>

<style scoped>
.omen-poster-img {
  height: 90vh;
}
.w-fit-content {
  width: fit-content;
}
</style>
