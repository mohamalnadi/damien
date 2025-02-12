<template>
  <div class="align-center d-flex">
    <div class="align-center d-flex flex-wrap pl-2">
      <div v-for="(action, key) in courseActions" :key="key" class="align-center d-flex">
        <div :class="`evaluation-${key}-btn`">
          <v-btn
            :id="`apply-course-action-btn-${key}`"
            :key="key"
            class="text-capitalize text-nowrap mx-0 px-2"
            :color="theme.current.dark ? 'tertiary' : 'secondary'"
            :disabled="disableControls || !allowEdits || !selectedEvaluationIds.length || isLoading || isInvalidAction(action)"
            @click.stop="action.apply(key)"
          >
            <span v-if="!(isLoading && key !== 'duplicate' && applyingAction.key === key)">{{ action.text }}</span>
            <v-progress-circular
              v-if="isLoading && key !== 'duplicate' && applyingAction.key === key"
              :indeterminate="true"
              color="tertiary"
              rotate="5"
              size="20"
              width="3"
            />
          </v-btn>
        </div>
        <div v-if="key === 'ignore'" class="align-self-center pt-1 px-1">
          <span class="font-size-18 text--secondary">|</span>
        </div>
      </div>
    </div>
    <UpdateEvaluations
      action="Duplicate"
      :apply-action="onConfirmDuplicate"
      :cancel-action="onCancelDuplicate"
      :is-applying="isApplying"
      :is-updating="isDuplicating"
      :midterm-form-available="midtermFormAvailable"
      v-bind="bulkUpdateOptions"
    />
    <UpdateEvaluations
      action="Edit"
      :apply-action="onConfirmEdit"
      :cancel-action="onCancelEdit"
      :is-applying="isApplying"
      :is-updating="isEditing"
      v-bind="bulkUpdateOptions"
    >
      <template #status="{status, on}">
        <v-row class="d-flex align-center" dense>
          <v-col cols="4">
            <label
              id="update-evaluations-select-status-label"
              for="update-evaluations-select-status"
              class="v-label"
            >
              Status:
            </label>
          </v-col>
          <v-col cols="8">
            <select
              id="update-evaluations-select-status"
              class="native-select-override bulk-action-form-input light"
              :disabled="disableControls"
              :status="status"
              :value="status"
              v-on="on"
            >
              <option v-for="s in EVALUATION_STATUSES" :key="s.text" :value="s.value">{{ s.text }}</option>
            </select>
          </v-col>
        </v-row>
      </template>
      <template #form="{form, on}">
        <v-row class="d-flex align-center" dense>
          <v-col cols="4">
            <label
              id="update-evaluations-select-form-label"
              for="update-evaluations-select-form"
              class="v-label"
            >
              Department Form:
            </label>
          </v-col>
          <v-col>
            <select
              id="update-evaluations-select-form"
              class="native-select-override bulk-action-form-input light"
              :disabled="disableControls"
              :form="form"
              :value="form"
              v-on="on"
            >
              <option v-for="df in activeDepartmentForms" :key="df.id" :value="df.id">{{ df.name }}</option>
            </select>
          </v-col>
        </v-row>
      </template>
    </UpdateEvaluations>
    <ConfirmDialog
      v-if="markAsDoneWarning"
      confirm-button-label="Proceed"
      :disabled="disableControls"
      :icon="mdiAlertCircle"
      :on-click-cancel="() => markAsDoneWarning = undefined"
      :on-click-confirm="onProceedMarkAsDone"
      :text="markAsDoneWarning"
      title="Warning"
    />
  </div>
</template>

<script setup>
import ConfirmDialog from '@/components/util/ConfirmDialog'
import UpdateEvaluations from '@/components/evaluation/UpdateEvaluations'
import {EVALUATION_STATUSES, useDepartmentStore} from '@/stores/department/department-edit-session'
import {alertScreenReader, putFocusNextTick} from '@/lib/utils'
import {chain, each, every, filter as _filter, get, has, includes, map, uniq} from 'lodash'
import {computed, onMounted, ref} from 'vue'
import {mdiAlertCircle} from '@mdi/js'
import {storeToRefs} from 'pinia'
import {toFormatFromISO} from '@/lib/utils'
import {updateEvaluations} from '@/api/departments'
import {useContextStore} from '@/stores/context'
import {useTheme} from 'vuetify'
import {validateConfirmable, validateDuplicable, validateMarkAsDone} from '@/stores/department/utils'

const departmentStore = useDepartmentStore()
const {activeDepartmentForms, department, disableControls, evaluations, selectedEvaluationIds} = storeToRefs(departmentStore)

const applyingAction = ref(undefined)
const bulkUpdateOptions = ref({
  departmentForm: undefined,
  evaluationStatus: undefined,
  evaluationType: undefined,
  instructor: undefined,
  midtermFormEnabled: false,
  startDate: undefined
})
const courseActions = ref({})
const isApplying = ref(false)
const isDuplicating = ref(false)
const isEditing = ref(false)
const isLoading = ref(false)
const markAsDoneWarning = ref(undefined)
const midtermFormAvailable = ref(false)
const theme = useTheme()

const allowEdits = computed(() => {
  const currentUser = useContextStore().currentUser
  return currentUser.isAdmin || !useContextStore().isSelectedTermLocked
})
const selectedEvaluations = computed(() => {
  return _filter(evaluations.value, e => selectedEvaluationIds.includes(e.id))
})
onMounted(() => {
  courseActions.value = {
    // TO DO: Clean up dictionary keys and statuses
    review: {
      apply: onClickReview,
      completedText: 'Marked as to-do',
      inProgressText: 'Marking as to-do',
      key: 'review',
      status: 'review',
      text: 'Mark as to-do'
    },
    confirm: {
      apply: onClickMarkDone,
      completedText: 'Marked as done',
      inProgressText: 'Marking as done',
      key: 'confirm',
      status: 'confirmed',
      text: 'Mark as done'
    },
    unmark: {
      apply: onClickUnmark,
      completedText: 'Unmarked',
      inProgressText: 'Unmarking',
      key: 'unmark',
      status: null,
      text: 'Unmark'
    },
    ignore: {
      apply: onClickIgnore,
      completedText: 'Ignored',
      inProgressText: 'Ignoring',
      key: 'ignore',
      status: 'ignore',
      text: 'Ignore'
    },
    duplicate: {
      apply: onClickDuplicate,
      completedText: 'Duplicated',
      inProgressText: 'Duplicating',
      key: 'duplicate',
      text: 'Duplicate'
    },
    edit: {
      apply: onClickEdit,
      completedText: 'Edited',
      inProgressText: 'Editing',
      key: 'edit',
      text: 'Edit'
    }
  }
})

const onCancelDuplicate = () => {
  reset()
  alertScreenReader('Canceled duplication.')
  putFocusNextTick('apply-course-action-btn-duplicate')
}

const onCancelEdit = () => {
  reset()
  alertScreenReader('Canceled edit.')
  putFocusNextTick('apply-course-action-btn-edit')
}

const onClickDuplicate = () => {
  showUpdateOptions()
  bulkUpdateOptions.value.instructor = {}
  midtermFormAvailable.value = department.value.usesMidtermForms
  if (midtermFormAvailable.value) {
    // Show midterm form option only if a midterm form exists for all selected evals.
    const availableFormNames = map(activeDepartmentForms.value, 'name')
    each(selectedEvaluations.value, e => {
      const formName = get(e, 'departmentForm.name')
      if (!formName || !(formName.endsWith('_MID') || availableFormNames.includes(formName + '_MID'))) {
        midtermFormAvailable.value = false
        return false
      }
    })
  }
  isDuplicating.value = true
  putFocusNextTick('update-evaluations-instructor-lookup-autocomplete')
}

const onClickEdit = () => {
  showUpdateOptions()
  // Pre-populate form if shared by all selected evals
  const uniqueForms = chain(selectedEvaluations.value).map(e => get(e, 'departmentForm.id')).uniq().value()
  if (uniqueForms.length === 1) {
    bulkUpdateOptions.value.departmentForm = get(selectedEvaluations.value, '0.departmentForm.id')
  }
  // Show instructor lookup if instructor is missing from all selected evals
  if (every(selectedEvaluations.value, {'instructor': null})) {
    bulkUpdateOptions.value.instructor = {}
  }
  // Pre-populate status if shared by all selected evals
  const uniqueStatuses = chain(selectedEvaluations.value).map(e => get(e, 'status')).uniq().value()
  if (uniqueStatuses.length === 1) {
    bulkUpdateOptions.value.evaluationStatus = get(selectedEvaluations.value, '0.status', 'none')
  }
  isEditing.value = true
  putFocusNextTick('update-evaluations-select-status')
}

const onClickIgnore = key => {
  validateAndUpdate(key)
}

const onClickMarkDone = key => {
  const selected = _filter(evaluations.value, e => includes(selectedEvaluationIds.value, e.id))
  markAsDoneWarning.value = validateMarkAsDone(selected)
  if (!markAsDoneWarning.value) {
    validateAndUpdate(key)
  }
}

const onClickReview = key => {
  validateAndUpdate(key)
}

const onClickUnmark = key => {
  validateAndUpdate(key)
}

const onConfirmDuplicate = options => {
  bulkUpdateOptions.value = options
  validateAndUpdate('duplicate')
}

const onConfirmEdit = options => {
  const selected = _filter(evaluations.value, e => includes(selectedEvaluationIds.value, e.id))
  bulkUpdateOptions.value = options
  if ('confirmed' === bulkUpdateOptions.value.evaluationStatus) {
    markAsDoneWarning.value = validateMarkAsDone(selected)
  }
  if (!markAsDoneWarning.value) {
    validateAndUpdate('edit')
  }
}

const onProceedMarkAsDone = () => {
  markAsDoneWarning.value = null
  validateAndUpdate(isEditing.value ? 'edit' : 'confirm')
}

const getEvaluationFieldsForUpdate = key => {
  let fields = null
  if (['duplicate', 'edit'].includes(key)) {
    fields = {}
    if (bulkUpdateOptions.value.departmentForm) {
      fields.departmentFormId = bulkUpdateOptions.value.departmentForm
    }
    if (has(bulkUpdateOptions.value, 'evaluationStatus')) {
      fields.status = bulkUpdateOptions.value.evaluationStatus
    }
    if (bulkUpdateOptions.value.evaluationType) {
      fields.evaluationTypeId = bulkUpdateOptions.value.evaluationType
    }
    if (bulkUpdateOptions.value.instructor) {
      fields.instructorUid = get(bulkUpdateOptions.value.instructor, 'uid')
    }
    if (bulkUpdateOptions.value.startDate) {
      fields.startDate = toFormatFromISO(bulkUpdateOptions.value.startDate, 'y-LL-dd')
    }
    if (key === 'duplicate') {
      if (bulkUpdateOptions.value.midtermFormEnabled) {
        fields.midterm = 'true'
      }
    }
  }
  return fields
}

const isInvalidAction = action => {
  const uniqueStatuses = uniq(evaluations.value.filter(e => selectedEvaluationIds.value.includes(e.id)).map(e => e.status))
  return (uniqueStatuses.length === 1 && uniqueStatuses[0] === action.status)
}

const reset = () => {
  bulkUpdateOptions.value = {
    departmentForm: null,
    evaluationStatus: null,
    evaluationType: null,
    instructor: null,
    midtermFormEnabled: false,
    startDate: null,
  }
  isDuplicating.value = false
  isEditing.value = false
  applyingAction.value = null
  isApplying.value = false
  isLoading.value = false
  markAsDoneWarning.value = null
  midtermFormAvailable.value = false
}

const showUpdateOptions = () => {
  // Pre-populate start date if shared by all selected evals.
  const uniqueStartDates = chain(selectedEvaluations.value).map(e => new Date(e.startDate).toDateString()).uniq().value()
  if (uniqueStartDates.length === 1) {
    bulkUpdateOptions.value.startDate = new Date(uniqueStartDates[0])
  }
  // Pre-populate type if shared by all selected evals
  const uniqueTypes = chain(selectedEvaluations.value).map(e => get(e, 'evaluationType.id')).uniq().value()
  if (uniqueTypes.length === 1) {
    bulkUpdateOptions.value.evaluationType = get(selectedEvaluations.value, '0.evaluationType.id')
  }
}

const update = (fields, key) => {
  disableControls.value = true
  isLoading.value = true
  const selectedCourseNumbers = uniq(evaluations.value
    .filter(e => selectedEvaluationIds.value.includes(e.id))
    .map(e => e.courseNumber))
  const refresh = () => {
    return selectedCourseNumbers.length === 1
      ? departmentStore.refreshSection({sectionId: selectedCourseNumbers[0], termId: useContextStore().selectedTermId})
      : departmentStore.refreshAll()
  }
  updateEvaluations(
    department.value.id,
    key,
    selectedEvaluationIds.value,
    useContextStore().selectedTermId,
    fields
  ).then(
    response => {
      refresh().then(() => {
        const selectedRowCount = applyingAction.value.key === 'duplicate' ? ((response.length || 0) / 2) : (response.length || 0)
        const target = `${selectedRowCount} ${selectedRowCount === 1 ? 'row' : 'rows'}`
        alertScreenReader(`${applyingAction.value.completedText} ${target}`)
        putFocusNextTick('select-all-evals-checkbox')
        reset()
      }).finally(() => {
        isApplying.value = false
        disableControls.value = false
      })
    },
    error => {
      departmentStore.showErrorDialog(get(error, 'response.data.message', 'An unknown error occurred.'))
      disableControls.value = false
      isApplying.value = false
      isLoading.value = false
    }
  )
}

const validateAndUpdate = key => {
  let valid = true
  const target = `${selectedEvaluationIds.value.length || 0} ${selectedEvaluationIds.value.length === 1 ? 'row' : 'rows'}`
  applyingAction.value = courseActions.value[key]
  isApplying.value = true
  alertScreenReader(`${applyingAction.value.inProgressText} ${target}`)

  const fields = getEvaluationFieldsForUpdate(key)
  if (key === 'duplicate') {
    valid = validateDuplicable(selectedEvaluationIds.value, fields)
  } else if (key === 'confirm' || (key === 'edit' && bulkUpdateOptions.value.evaluationStatus === 'confirmed')) {
    valid = validateConfirmable(selectedEvaluationIds.value, fields)
  }
  if (valid) {
    update(fields, key)
  } else {
    isApplying.value = false
  }
}
</script>

<style scoped>
.evaluation-confirm-btn {
  min-width: 7.6em
}
.evaluation-duplicate-btn {
  min-width: 5.45em
}
.evaluation-edit-btn {
  min-width: 4.02em
}
.evaluation-ignore-btn {
  min-width: 4.05em
}
.evaluation-review-btn {
  min-width: 7.84em
}
.evaluation-unmark-btn {
  min-width: 4.65em
}
</style>
