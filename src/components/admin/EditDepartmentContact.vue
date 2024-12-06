<template>
  <v-form
    v-model="valid"
    class="px-5 py-4"
    :class="{'bg-surface-variant': uid && !contact}"
    lazy-validation
  >
    <div v-if="!contact && !uid" class="w-75">
      <h3 id="add-contact-sub-header" class="form-title">
        Add Contact
      </h3>
      <PersonLookup
        class="my-2"
        :exclude-uids="map(contacts, 'uid')"
        label="Contact"
        label-class="sr-only"
        list-label="Suggested Contacts List"
        :on-select-result="onSelectSearchResult"
      />
    </div>
    <div v-if="uid" class="department-contact-form w-75">
      <h3 id="contact-sub-header">
        <span class="sr-only">Contact: </span>{{ fullName }} ({{ uid }})
      </h3>
      <div class="pt-3">
        <label :for="`input-email-${contactId}`" class="form-label">
          Email Address
        </label>
        <v-text-field
          :id="`input-email-${contactId}`"
          v-model="email"
          class="mt-1"
          density="compact"
          variant="outlined"
          required
          :rules="emailRules"
        />
      </div>
      <div class="pt-1">
        <label :for="`checkbox-communications-${contactId}`" class="form-label">
          Communications
        </label>
        <div class="align-center d-flex">
          <v-checkbox
            :id="`checkbox-communications-${contactId}`"
            v-model="canReceiveCommunications"
            aria-label="Receive notifications"
            class="checkbox-override rounded-sm"
            color="tertiary"
            density="compact"
            hide-details
            role="checkbox"
            tabindex="0"
          />
          <label class="v-label ml-1" :for="`checkbox-communications-${contactId}`">
            Receive notifications
          </label>
        </div>
      </div>
      <div class="pt-2">
        <label :for="`checkbox-communications-${contactId}`" class="form-label">
          Blue Access
        </label>
        <v-radio-group
          v-model="permissions"
          class="mt-1"
          color="tertiary"
          column
          density="comfortable"
          hide-details
          mandatory
        >
          <v-radio
            :id="`radio-no-blue-${contactId}`"
            :aria-checked="isNil(permissions)"
            label="No access to Blue"
            :value="null"
          />
          <v-radio
            :id="`radio-reports-only-${contactId}`"
            :aria-checked="permissions === 'reports_only'"
            label="View reports"
            value="reports_only"
          />
          <v-radio
            :id="`radio-response-rates-${contactId}`"
            :aria-checked="permissions === 'response_rates'"
            label="View reports and response rates"
            value="response_rates"
          />
        </v-radio-group>
      </div>
      <div class="pt-2">
        <label :for="`select-deptForms-${contactId}`" class="form-label">
          Department Forms
        </label>
        <v-combobox
          :id="`select-deptForms-${contactId}`"
          v-model="contactDepartmentForms"
          aria-label="Department Forms"
          auto-select-first
          autocomplete="off"
          chips
          class="mt-2"
          closable-chips
          color="primary"
          density="comfortable"
          hide-details
          hide-selected
          item-title="name"
          item-value="id"
          :items="availableDepartmentForms"
          :menu-props="{closeOnClick: true, closeOnContentClick: true}"
          multiple
          return-object
          variant="outlined"
          @change="onChangeContactDepartmentForms"
        >
          <template #chip="{item}">
            <v-chip
              :id="`selected-deptForm-${item.raw.id}-${contactId}`"
              :key="item.id"
              :close-label="`Remove ${item.title} from ${fullName}'s department forms`"
              color="tertiary"
              :text="item.title"
              @click:close="remove(item)"
            />
          </template>
        </v-combobox>
      </div>
    </div>
    <div class="pt-3">
      <ProgressButton
        :id="`save-dept-contact-${contactId}-btn`"
        :action="onSave"
        class="text-capitalize mr-2"
        :disabled="!valid || !uid || isSaving"
        :in-progress="isSaving"
        text="Save"
      />
      <v-btn
        :id="`cancel-dept-contact-${contactId}-btn`"
        class="text-capitalize"
        variant="outlined"
        text="Cancel"
        @click.prevent="onCancel"
      />
    </div>
  </v-form>
</template>

<script setup>
import PersonLookup from '@/components/admin/PersonLookup'
import ProgressButton from '@/components/util/ProgressButton'
import {alertScreenReader, oxfordJoin, putFocusNextTick} from '@/lib/utils'
import {cloneDeep, differenceBy, find, findIndex, get, isNil, map, sortBy} from 'lodash'
import {computed, onMounted, ref, watch} from 'vue'
import {getUserDepartmentForms} from '@/api/user'
import {storeToRefs} from 'pinia'
import {useDepartmentStore} from '@/stores/department/department-edit-session'

const props = defineProps({
  afterSave: {
    required: true,
    type: Function
  },
  contact: {
    default: () => {},
    required: false,
    type: Object
  },
  onCancel: {
    required: true,
    type: Function
  }
})

const departmentStore = useDepartmentStore()

const {contacts} = storeToRefs(departmentStore)
const canReceiveCommunications = ref(true)
const csid = ref(undefined)
const contactDepartmentForms = ref([])
const email = ref(undefined)
const emailRules = [
  v => !!v || 'E-mail is required',
  v => /.+@.+\..+/.test(v) || 'E-mail must be valid'
]
const firstName = ref(undefined)
const isSaving = ref(false)
const lastName = ref(undefined)
const permissions = ref(undefined)
const uid = ref(undefined)
const userId = ref(undefined)
const valid = ref(true)

const availableDepartmentForms = computed(() => {
  return differenceBy(departmentStore.allDepartmentForms, contactDepartmentForms.value, item => item.name)
})
const contactId = computed(() => {
  return get(props.contact, 'uid', 'add-contact')
})
const fullName = computed(() => {
  return firstName.value && lastName.value ? `${firstName.value} ${lastName.value}`.trim() : ''
})

watch(canReceiveCommunications, value => {
  srAlert('receive notifications', value)
})

watch(contactDepartmentForms, (val, prev) => {
  if (!val || !prev || val.length === prev.length) return
  contactDepartmentForms.value = val.map(item => {
    if (typeof item === 'string') {
      return find(availableDepartmentForms.value, {'name': item})
    } else {
      return item
    }
  }).filter(v => v)
})

watch(permissions, value => {
  if (isNil(value)) {
    srAlert('have access to Blue', false)
  } else if (value === 'reports_only') {
    srAlert('be able to view reports', true)
  } else if (value === 'response_rates') {
    srAlert('be able to view reports and response rates', true)
  }
})

onMounted(() => {
  populateForm(props.contact)
  putFocusNextTick('add-contact-sub-header')
})

const fetchUserDepartmentForms = uid => {
  getUserDepartmentForms(uid).then(data => {
    contactDepartmentForms.value = data
  })
}

const onChangeContactDepartmentForms = selectedValues => {
  const names = map(selectedValues, 'name')
  if (names.length) {
    alertScreenReader(`Selected department form${names.length === 1 ? 's are' : 'is'} ${oxfordJoin(names)}.`)
  } else {
    alertScreenReader('No department forms selected.')
  }
}

const onSave = () => {
  isSaving.value = true
  alertScreenReader('Saving')
  departmentStore.updateContact({
    canReceiveCommunications: canReceiveCommunications.value,
    canViewReports: permissions.value === 'reports_only',
    canViewResponseRates: permissions.value === 'response_rates',
    csid: csid.value,
    departmentForms: contactDepartmentForms.value,
    email: email.value,
    firstName: firstName.value,
    lastName: lastName.value,
    uid: uid.value,
    userId: userId.value
  }).then(() => {
    props.afterSave()
    isSaving.value = false
  })
}

const onSelectSearchResult = user => {
  populateForm(user)
  alertScreenReader(`${user.firstName} ${user.lastName} selected`)
}

const populateForm = contact => {
  if (contact) {
    fetchUserDepartmentForms(contact.uid)
    csid.value = contact.csid
    contactDepartmentForms.value = cloneDeep(sortBy(contact.departmentForms, 'name'))
    email.value = contact.email
    firstName.value = contact.firstName
    lastName.value = contact.lastName
    uid.value = contact.uid
    userId.value = contact.userId
    if (contact.canReceiveCommunications !== undefined) {
      canReceiveCommunications.value = contact.canReceiveCommunications
    }
    if (contact.canViewReports) {
      permissions.value = contact.canViewResponseRates.value ? 'response_rates' : 'reports_only'
    }
    putFocusNextTick('person-lookup-input')
  } else {
    csid.value = null
    canReceiveCommunications.value = true
    contactDepartmentForms.value = null
    email.value = null
    firstName.value = null
    lastName.value = null
    permissions.value = null
    uid.value = null
    userId.value = null
  }
}

const remove = departmentForm => {
  const formName = departmentForm.name
  const indexOf = findIndex(contactDepartmentForms.value, {'name': formName})
  contactDepartmentForms.value.splice(indexOf, 1)
  alertScreenReader(`Removed ${formName} from ${fullName.value} department forms.`)
  putFocusNextTick(`input-deptForms-${contactId.value}`)
}

const srAlert = (label, isSelected) => {
  if (firstName.value || lastName.value) {
    alertScreenReader(`${firstName.value} ${lastName.value} will ${isSelected ? '' : 'not '} ${label}.`)
  }
}
</script>

<style>
.form-title {
  font-size: 18px;
  font-weight: 700;
  line-height: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>

<style scoped>
.department-contact-form {
  z-index: 10;
}
.checkbox-override.v-simple-checkbox div {
  height: 20px;
  margin: 0px;
  width: 20px;
}
</style>
