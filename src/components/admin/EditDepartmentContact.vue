<template>
  <v-form
    v-model="valid"
    class="pa-3"
    lazy-validation
  >
    <div v-if="!contact">
      <h3 id="add-contact-sub-header" class="form-title my-2" tabindex="-1">
        Add Contact
      </h3>
      <PersonLookup
        class="mt-1 mb-4"
        :exclude-uids="map(contacts, 'uid')"
        :on-select-result="onSelectSearchResult"
      />
    </div>
    <div v-if="uid" class="department-contact-form">
      <label :for="`input-email-${contactId}`" class="form-label">
        Email Address
      </label>
      <v-text-field
        :id="`input-email-${contactId}`"
        v-model="email"
        class="mt-1"
        color="tertiary"
        dense
        :disabled="disableControls"
        outlined
        required
        :rules="emailRules"
      />
      <legend :for="`checkbox-communications-${contactId}`" class="form-label">
        Communications
      </legend>
      <div class="d-flex my-2">
        <v-checkbox
          :id="`checkbox-communications-${contactId}`"
          :aria-checked="canReceiveCommunications"
          aria-label="Receive notifications"
          class="checkbox-override rounded-sm"
          color="tertiary"
          :disabled="disableControls"
          :ripple="false"
          role="checkbox"
          tabindex="0"
          :value="canReceiveCommunications"
          @input="() => canReceiveCommunications = !canReceiveCommunications"
        />
        <label
          class="v-label d-flex align-center"
          :class="theme.global.current.value.dark ? 'theme--dark' : 'theme--light'"
          :for="`checkbox-communications-${contactId}`"
        >
          Receive notifications
        </label>
      </div>
      <legend :for="`checkbox-communications-${contactId}`" class="form-label">
        Blue Access
      </legend>
      <v-radio-group
        v-model="permissions"
        class="mt-1"
        column
        dense
        :disabled="disableControls"
        mandatory
      >
        <v-radio
          :id="`radio-no-blue-${contactId}`"
          :aria-checked="isNil(permissions)"
          class="mb-1"
          color="tertiary"
          label="No access to Blue"
          :value="null"
        />
        <v-radio
          :id="`radio-reports-only-${contactId}`"
          :aria-checked="permissions === 'reports_only'"
          class="mb-1"
          color="tertiary"
          label="View reports"
          value="reports_only"
        />
        <v-radio
          :id="`radio-response-rates-${contactId}`"
          :aria-checked="permissions === 'response_rates'"
          class="mb-1"
          color="tertiary"
          label="View reports and response rates"
          value="response_rates"
        />
      </v-radio-group>
      <legend :for="`select-deptForms-${contactId}`" class="form-label">
        Department Forms
      </legend>
      <v-combobox
        v-model="contactDepartmentForms"
        aria-label="Department Forms"
        auto-select-first
        chips
        class="mb-4 mt-2"
        color="tertiary"
        deletable-chips
        dense
        :disabled="disableControls"
        hide-details
        hide-selected
        item-color="secondary"
        item-text="name"
        :items="availableDepartmentForms"
        :menu-props="{closeOnClick: true, closeOnContentClick: true}"
        multiple
        outlined
        return-object
        @change="onChangeContactDepartmentForms"
      >
        <template #selection="data">
          <v-chip
            :id="`selected-deptForm-${data.item.id}-${contactId}`"
            :key="data.item.id"
            v-bind="data.attrs"
            :aria-label="`Remove ${data.item.name} from ${fullName}'s department forms`"
            class="px-4 ma-1"
            close
            :close-label="`Remove ${data.item.name} from ${fullName}'s department forms`"
            color="secondary"
            :disabled="disableControls"
            :ripple="false"
            @click:close="remove(data.item)"
          >
            {{ data.item.name }}
          </v-chip>
        </template>
      </v-combobox>
    </div>
    <v-btn
      :id="`save-dept-contact-${contactId}-btn`"
      class="text-capitalize mr-2"
      color="secondary"
      :disabled="disableControls || !valid || !uid"
      elevation="2"
      @click.prevent="onSave"
    >
      Save
    </v-btn>
    <v-btn
      :id="`cancel-dept-contact-${contactId}-btn`"
      class="text-capitalize ml-1"
      :disabled="disableControls"
      elevation="2"
      outlined
      text
      @click.prevent="onCancel"
    >
      Cancel
    </v-btn>
  </v-form>
</template>

<script setup>
import {storeToRefs} from 'pinia'
import {useDepartmentStore} from '@/stores/department/department-edit-session'

const {contacts, disableControls} = storeToRefs(useDepartmentStore())
</script>

<script>
import PersonLookup from '@/components/admin/PersonLookup'
import {alertScreenReader, oxfordJoin, putFocusNextTick} from '@/lib/utils'
import {
  cloneDeep,
  differenceBy,
  findIndex,
  get,
  isNil,
  last,
  map,
  sortBy
} from 'lodash'
import {getUserDepartmentForms} from '@/api/user'
import {useTheme} from 'vuetify'

export default {
  name: 'EditDepartmentContact',
  components: {PersonLookup},
  props: {
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
  },
  data: () => ({
    canReceiveCommunications: true,
    csid: undefined,
    contactDepartmentForms: undefined,
    email: undefined,
    emailRules: [
      v => !!v || 'E-mail is required',
      v => /.+@.+\..+/.test(v) || 'E-mail must be valid',
    ],
    firstName: undefined,
    lastName: undefined,
    permissions: undefined,
    theme: useTheme(),
    uid: undefined,
    userId: undefined,
    valid: true
  }),
  computed: {
    availableDepartmentForms() {
      return differenceBy(useDepartmentStore().allDepartmentForms, this.contactDepartmentForms, item => item.name)
    },
    contactId() {
      return get(this.contact, 'uid', 'add-contact')
    },
    fullName() {
      return this.firstName && this.lastName ? `${this.firstName} ${this.lastName}`.trim() : ''
    }
  },
  watch: {
    canReceiveCommunications(value) {
      this.srAlert('receive notifications', value)
    },
    contactDepartmentForms(val, prev) {
      if (!val || !prev || val.length === prev.length) return
      this.contactDepartmentForms = val.map(item => {
        if (typeof item === 'string') {
          return find(this.availableDepartmentForms, {'name': item})
        } else {
          return item
        }
      }).filter(v => v)
    },
    permissions(value) {
      if (isNil(value)) {
        this.srAlert('have access to Blue', false)
      } else if (value === 'reports_only') {
        this.srAlert('be able to view reports', true)
      } else if (value === 'response_rates') {
        this.srAlert('be able to view reports and response rates', true)
      }
    }
  },
  created() {
    this.populateForm(this.contact)
    putFocusNextTick('add-contact-sub-header')
    alertScreenReader(`${this.contact ? 'Edit' : 'Add'} department contact form is ready`)
  },
  methods: {
    isNil,
    afterSelectDepartmentForm(departmentForms) {
      const selected = last(departmentForms)
      alertScreenReader(`Added ${selected.name}.`)
      putFocusNextTick(`input-deptForms-${this.contactId}`)
    },
    fetchUserDepartmentForms(uid) {
      getUserDepartmentForms(uid).then(data => {
        this.contactDepartmentForms = data
      })
    },
    onChangeContactDepartmentForms(selectedValues) {
      const names = map(selectedValues, 'name')
      if (names.length) {
        alertScreenReader(`Selected department form${names.length === 1 ? 's are' : 'is'} ${oxfordJoin(names)}.`)
      } else {
        alertScreenReader('No department forms selected.')
      }
    },
    onSave() {
      alertScreenReader('Saving')
      useDepartmentStore().updateContact({
        'canReceiveCommunications': this.canReceiveCommunications,
        'canViewReports': this.permissions === 'reports_only',
        'canViewResponseRates': this.permissions === 'response_rates',
        'csid': this.csid,
        'departmentForms': this.contactDepartmentForms,
        'email': this.email,
        'firstName': this.firstName,
        'lastName': this.lastName,
        'uid': this.uid,
        'userId': this.userId
      }).then(this.afterSave)
    },
    onSelectSearchResult(user) {
      this.populateForm(user)
    },
    populateForm(contact) {
      if (contact) {
        this.fetchUserDepartmentForms(contact.uid)
        this.csid = contact.csid
        this.contactDepartmentForms = cloneDeep(sortBy(contact.departmentForms, 'name'))
        this.email = contact.email
        this.firstName = contact.firstName
        this.lastName = contact.lastName
        this.uid = contact.uid
        this.userId = contact.userId
        if (contact.canReceiveCommunications !== undefined) {
          this.canReceiveCommunications = contact.canReceiveCommunications
        }
        if (contact.canViewReports) {
          this.permissions = contact.canViewResponseRates ? 'response_rates' : 'reports_only'
        }
        putFocusNextTick('input-person-lookup-autocomplete')
      } else {
        this.csid = null
        this.canReceiveCommunications = true
        this.contactDepartmentForms = null
        this.email = null
        this.firstName = null
        this.lastName = null
        this.permissions = null
        this.uid = null
        this.userId = null
      }
    },
    remove(departmentForm) {
      const formName = departmentForm.name
      const indexOf = findIndex(this.contactDepartmentForms, {'name': formName})
      this.contactDepartmentForms.splice(indexOf, 1)
      alertScreenReader(`Removed ${formName} from ${this.fullName} department forms.`)
      putFocusNextTick(`input-deptForms-${this.contactId}`)
    },
    srAlert(label, isSelected) {
      if (this.firstName || this.lastName) {
        alertScreenReader(`${this.firstName} ${this.lastName} will ${isSelected ? '' : 'not '} ${label}.`)
      }
    }
  }
}
</script>

<style>
.department-contact-form {
  z-index: 10;
}
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
.checkbox-override.v-simple-checkbox {
  left: -2px;
  margin-right: 4px;
  padding: 4px;
}
.checkbox-override.v-simple-checkbox div {
  height: 20px;
  margin: 0px;
  width: 20px;
}
</style>
