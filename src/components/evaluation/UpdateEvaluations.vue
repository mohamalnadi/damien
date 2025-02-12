<template>
  <v-dialog
    v-model="model"
    aria-labelledby="update-evaluations-dialog-title"
    class="overflow-y-visible"
    width="800"
    v-bind="$attrs"
    @click:outside="onClickCancel"
    @keydown.esc="onClickCancel"
  >
    <v-card>
      <v-card-title id="update-evaluations-dialog-title" tabindex="-1">{{ action }} {{ selectedEvaluationsDescription }}</v-card-title>
      <v-card-text class="px-0 pb-0">
        <v-container class="px-8 pb-4">
          <slot name="status" :status="selectedEvaluationStatus" :on="{change: e => selectedEvaluationStatus = e.target.value}"></slot>
          <PersonLookup
            v-if="isObject(instructor)"
            id="update-evaluations-instructor-lookup-autocomplete"
            container-class="flex-row py-1"
            :disabled="disableControls"
            :inline="true"
            input-class="bulk-action-form-input"
            :instructor-lookup="true"
            label="Instructor: "
            label-class="v-label d-flex text-nowrap align-center"
            :on-select-result="selectInstructor"
            placeholder="Name or UID"
            :required="isInstructorRequired"
            solo
            :value="selectedInstructor"
          />
          <v-row v-if="midtermFormAvailable" class="d-flex align-center" dense>
            <v-col cols="4"></v-col>
            <v-col cols="8">
              <v-checkbox
                v-model="midtermFormEnabled"
                class="bulk-action-form-input text-nowrap my-1"
                color="tertiary"
                :disabled="disableControls"
                hide-details
                label="Use midterm department forms"
                :ripple="false"
              />
            </v-col>
          </v-row>
          <slot name="form" :form="selectedDepartmentForm" :on="{change: e => selectedDepartmentForm = toInteger(e.target.value)}"></slot>
          <v-row class="d-flex align-center" dense>
            <v-col cols="4">
              <label
                id="update-evaluations-select-type-label"
                for="update-evaluations-select-type"
                class="v-label d-block text-nowrap py-1"
              >
                Evaluation Type:
              </label>
            </v-col>
            <v-col cols="8">
              <select
                id="update-evaluations-select-type"
                v-model="selectedEvaluationType"
                class="native-select-override bulk-action-form-input light"
                :disabled="disableControls"
              >
                <option v-for="et in evaluationTypes" :key="et.id" :value="et.id">{{ et.name }}</option>
              </select>
            </v-col>
          </v-row>
          <v-row class="d-flex align-center" dense>
            <v-col cols="4">
              <label
                for="update-evaluations-start-date"
                class="v-label text-nowrap"
                :class="theme.global.current.value.dark ? 'theme--dark' : 'theme--light'"
              >
                Evaluation Start Date:
              </label>
            </v-col>
            <v-col cols="8">
              <v-date-picker
                v-model="selectedStartDate"
                class="bulk-action-form-input"
                :min-date="get(validStartDates, 'min')"
                :max-date="get(validStartDates, 'max')"
                :popover="{positionFixed: true}"
                title-position="left"
              >
                <template #default="{ inputValue, inputEvents }">
                  <input
                    id="update-evaluations-start-date"
                    class="datepicker-input input-override light my-0"
                    :disabled="disableControls"
                    maxlength="10"
                    minlength="10"
                    :value="inputValue"
                    v-on="inputEvents"
                  />
                </template>
              </v-date-picker>
            </v-col>
          </v-row>
        </v-container>
        <div v-if="size(selectedEvaluations)" class="bulk-action-preview pt-2">
          <v-table dense class="bulk-action-preview-table">
            <caption class="bulk-action-preview-caption text-left"><div class="px-6 pb-3">Preview Your Changes</div></caption>
            <thead>
              <tr>
                <th
                  v-for="(clazz, colName) in previewHeaders"
                  :key="clazz"
                  class="px-1"
                  :class="clazz"
                >
                  {{ colName }}
                </th>
              </tr>
            </thead>
            <tbody>
              <template v-for="(evaluation, index) in selectedEvaluations" :key="index">
                <tr>
                  <td :id="`preview-${index}-status`" class="bulk-action-status-col pr-1">
                    <div v-if="evaluation.status" :class="{'text-decoration-line-through accent--text': action === 'Edit' && showSelectedStatus(evaluation)}">
                      {{ getStatusText(evaluation.status) }}
                    </div>
                    <div v-if="action === 'Edit' && showSelectedStatus(evaluation)">
                      {{ getStatusText(selectedEvaluationStatus) }}
                    </div>
                  </td>
                  <td :id="`preview-${index}-courseNumber`" class="bulk-action-courseNumber-col px-1">{{ evaluation.courseNumber }}</td>
                  <td :id="`preview-${index}-courseName`" class="bulk-action-courseName-col px-1">
                    <div>{{ evaluation.subjectArea }} {{ evaluation.catalogId }}</div>
                    <div>{{ evaluation.instructionFormat }} {{ evaluation.sectionNumber }}</div>
                  </td>
                  <td :id="`preview-${index}-instructor`" class="bulk-action-instructor-col px-1">
                    <div v-if="get(evaluation, 'instructor.uid')" :class="{'text-decoration-line-through accent--text': action === 'Edit' && showSelectedInstructor(evaluation)}">
                      {{ evaluation.instructor.firstName }} {{ evaluation.instructor.lastName }}
                      ({{ evaluation.instructor.uid }})
                    </div>
                    <div v-if="action === 'Edit' && showSelectedInstructor(evaluation)">
                      {{ selectedInstructor.firstName }} {{ selectedInstructor.lastName }}
                      ({{ selectedInstructor.uid }})
                    </div>
                  </td>
                  <td :id="`preview-${index}-departmentForm`" class="bulk-action-departmentForm-col px-1">
                    <div v-if="evaluation.departmentForm" :class="{'text-decoration-line-through accent--text': action === 'Edit' && showSelectedDepartmentForm(evaluation)}">
                      {{ evaluation.departmentForm.name }}
                    </div>
                    <div v-if="action === 'Edit' && showSelectedDepartmentForm(evaluation)">
                      {{ selectedDepartmentFormName }}
                    </div>
                  </td>
                  <td :id="`preview-${index}-evaluationType`" class="bulk-action-evaluationType-col px-1">
                    <div v-if="evaluation.evaluationType" :class="{'text-decoration-line-through accent--text accent--text': action === 'Edit' && showSelectedEvaluationType(evaluation)}">
                      {{ evaluation.evaluationType.name }}
                    </div>
                    <div v-if="action === 'Edit' && showSelectedEvaluationType(evaluation)">
                      {{ selectedEvaluationTypeName }}
                    </div>
                  </td>
                  <td :id="`preview-${index}-startDate`" class="bulk-action-startDate-col px-1">
                    <div v-if="evaluation.startDate" :class="{'text-decoration-line-through accent--text': action === 'Edit' && showSelectedStartDate(evaluation)}">
                      {{ toLocaleFromISO(evaluation.startDate, 'LL/dd/yyyy') }}
                    </div>
                    <div v-if="action === 'Edit' && showSelectedStartDate(evaluation)">
                      {{ toLocaleFromISO(selectedStartDate, 'LL/dd/yyyy') }}
                    </div>
                  </td>
                </tr>
                <tr v-if="action === 'Duplicate'" :key="`${index}-dupe`">
                  <td :id="`preview-${index}-dupe-status`" class="bulk-action-status-col pr-1"></td>
                  <td :id="`preview-${index}-dupe-courseNumber`" class="bulk-action-courseNumber-col px-1">{{ evaluation.courseNumber }}</td>
                  <td :id="`preview-${index}-dupe-courseName`" class="bulk-action-courseName-col px-1">
                    <div>{{ evaluation.subjectArea }} {{ evaluation.catalogId }}</div>
                    <div>{{ evaluation.instructionFormat }} {{ evaluation.sectionNumber }}</div>
                  </td>
                  <td :id="`preview-${index}-dupe-instructor`" class="bulk-action-instructor-col px-1">
                    <div v-if="showSelectedInstructor(evaluation)">
                      {{ selectedInstructor.firstName }} {{ selectedInstructor.lastName }}
                      ({{ selectedInstructor.uid }})
                    </div>
                    <div v-if="!showSelectedInstructor(evaluation) && evaluation.instructor">
                      {{ evaluation.instructor.firstName }} {{ evaluation.instructor.lastName }}
                      ({{ evaluation.instructor.uid }})
                    </div>
                  </td>
                  <td :id="`preview-${index}-dupe-departmentForm`" class="bulk-action-departmentForm-col px-1">
                    <template v-if="midtermFormEnabled && get(evaluation, 'departmentForm.name')">
                      {{ endsWith(evaluation.departmentForm.name, '_MID') ? evaluation.departmentForm.name : `${evaluation.departmentForm.name}_MID` }}
                    </template>
                    <template v-else>
                      {{ get(evaluation, 'departmentForm.name') }}
                    </template>
                  </td>
                  <td :id="`preview-${index}-dupe-evaluationType`" class="bulk-action-evaluationType-col px-1">
                    <div>
                      {{ showSelectedEvaluationType(evaluation) ? selectedEvaluationTypeName : get(evaluation, 'evaluationType.name') }}
                    </div>
                  </td>
                  <td :id="`preview-${index}-dupe-startDate`" class="bulk-action-startDate-col px-1">
                    <div>
                      {{ toLocaleFromISO(selectedStartDate || evaluation.startDate, 'LL/dd/yyyy') }}
                    </div>
                  </td>
                </tr>
              </template>
            </tbody>
          </v-table>
        </div>
      </v-card-text>
      <v-divider />
      <v-card-actions>
        <v-spacer />
        <div class="d-flex pa-2">
          <v-btn
            id="apply-course-action-btn"
            class="mt-2 mr-2"
            color="secondary"
            :disabled="disableApply"
            min-width="85"
            @click="onClickApply"
          >
            <span v-if="!isApplying">Apply</span>
            <v-progress-circular
              v-if="isApplying"
              :indeterminate="true"
              color="white"
              rotate="5"
              size="20"
              width="3"
            ></v-progress-circular>
          </v-btn>
          <v-btn
            id="cancel-duplicate-btn"
            class="mt-2 mr-2"
            :disabled="disableControls"
            @click="onClickCancel"
          >
            Cancel
          </v-btn>
        </div>
      </v-card-actions>
    </v-card>
    <ConfirmDialog
      v-if="isConfirmingNonSisInstructor"
      :disabled="disableControls"
      :on-click-cancel="onCancelNonSisInstructor"
      :on-click-confirm="onConfirmNonSisInstructor"
      :text="instructorConfirmationText(selectedInstructor)"
      title="Add new instructor?"
    />
  </v-dialog>
</template>

<script setup>
import ConfirmDialog from '@/components/util/ConfirmDialog'
import PersonLookup from '@/components/admin/PersonLookup'
import {EVALUATION_STATUSES, useDepartmentStore} from '@/stores/department/department-edit-session'
import {addInstructor} from '@/api/instructor'
import {computed, onMounted, ref, watch} from 'vue'
import {endsWith, find, get, isEmpty, isObject, map, max, min, reduce, size, toInteger} from 'lodash'
import {storeToRefs} from 'pinia'
import {toLocaleFromISO, toFormatFromISO} from '@/lib/utils'
import {useContextStore} from '@/stores/context'
import {useTheme} from 'vuetify'

const props = defineProps({
  action: {
    required: true,
    type: String
  },
  applyAction: {
    required: true,
    type: Function
  },
  cancelAction: {
    required: true,
    type: Function
  },
  departmentForm: {
    default: undefined,
    required: false,
    type: Number
  },
  evaluationStatus: {
    default: undefined,
    required: false,
    type: String
  },
  evaluationType: {
    default: undefined,
    required: false,
    type: Number
  },
  instructor: {
    default: undefined,
    required: false,
    type: Object
  },
  isApplying: {
    required: true,
    type: Boolean
  },
  isUpdating: {
    required: true,
    type: Boolean
  },
  midtermFormAvailable: {
    required: false,
    type: Boolean
  },
  startDate: {
    default: undefined,
    required: false,
    type: Date
  }
})

const {disableControls} = storeToRefs(useDepartmentStore())
const evaluationTypes = ref([])
const isConfirmingNonSisInstructor = ref(false)
const isInstructorRequired = ref(false)
const midtermFormEnabled = ref(false)
const model = ref(undefined)
const previewHeaders = {
  'Status': 'bulk-action-status-col',
  'Course Number': 'bulk-action-courseNumber-col',
  'Course Name': 'bulk-action-courseName-col',
  'Instructor': 'bulk-action-instructor-col',
  'Department Form': 'bulk-action-departmentForm-col',
  'Evaluation Type': 'bulk-action-evaluationType-col',
  'Start Date': 'bulk-action-startDate-col'
}
const selectedDepartmentForm = ref(undefined)
const selectedEvaluations = ref([])
const selectedEvaluationStatus = ref(undefined)
const selectedEvaluationType = ref(undefined)
const selectedInstructor = ref(undefined)
const selectedStartDate = ref(undefined)
const theme = useTheme()

const allowEdits = computed(() => {
  const currentUser = useContextStore().currentUser
  return currentUser.isAdmin || !useContextStore().isSelectedTermLocked
})
const disableApply = computed(() => {
  return disableControls.value ||
    !allowEdits.value ||
    (isInstructorRequired.value && !get(selectedInstructor.value, 'uid'))
})
const selectedDepartmentFormName = computed(() => {
  return get(find(useContextStore().config.departmentForms, df => df.id === selectedDepartmentForm.value), 'name')
})
const selectedEvaluationsDescription = computed(() => {
  if (isEmpty(useDepartmentStore().selectedEvaluationIds)) {
    return ''
  }
  return `${useDepartmentStore().selectedEvaluationIds.length} ${useDepartmentStore().selectedEvaluationIds.length === 1 ? 'row' : 'rows'}`
})
const selectedEvaluationTypeName = computed(() => {
  return get(find(useContextStore().config.evaluationTypes, et => et.id === selectedEvaluationType.value), 'name')
})
const selectedStartDay = computed(() => {
  return selectedStartDate.value ? toFormatFromISO(selectedStartDate.value, 'o') : null
})
const validStartDates = computed(() => {
  // The intersection of the selected rows' allowed evaluation start dates
  return {
    'max': min(map(selectedEvaluations.value, e => e.maxStartDate)),
    'min': max(map(selectedEvaluations.value, e => e.meetingDates.start))
  }
})

onMounted(() => {
  evaluationTypes.value = [{id: null, name: 'Default'}].concat(useContextStore().config.evaluationTypes)
  model.value = props.isUpdating
})

watch(midtermFormEnabled, v => {
  isInstructorRequired.value = !v
})
watch(props.isUpdating, v => {
  model.value = v
})
watch(model, () => {
  reset()
})

const getStatusText = status => {
  return status === 'none' ? null : get(find(EVALUATION_STATUSES, es => es.value === status), 'text')
}

const instructorConfirmationText = instructor => {
  return `
    ${instructor.firstName} ${instructor.lastName} (${instructor.uid})
    is not currently listed in SIS data as an instructor for any courses.`
}

const onCancelNonSisInstructor = () => {
  isConfirmingNonSisInstructor.value = false
  selectedInstructor.value = null
}

const onClickApply = () => {
  props.applyAction({
    departmentForm: selectedDepartmentForm.value,
    evaluationStatus: selectedEvaluationStatus.value === 'none' ? null : selectedEvaluationStatus.value,
    evaluationType: selectedEvaluationType.value,
    instructor: selectedInstructor.value || props.instructor,
    midtermFormEnabled: midtermFormEnabled.value,
    startDate: selectedStartDate.value
  })
  if (selectedInstructor.value && selectedInstructor.value.isSisInstructor === false) {
    addInstructor(selectedInstructor.value)
  }
}

const onClickCancel = () => {
  isInstructorRequired.value = false
  midtermFormEnabled.value = false
  selectedDepartmentForm.value = null
  selectedEvaluationStatus.value = null
  selectedEvaluationType.value = null
  selectedInstructor.value = null
  selectedStartDate.value = null
  props.cancelAction()
}

const onConfirmNonSisInstructor = () => {
  isConfirmingNonSisInstructor.value = false
}

const showSelectedDepartmentForm = evaluation => {
  return selectedDepartmentForm.value && selectedDepartmentForm.value !== get(evaluation, 'departmentForm.id')
}

const showSelectedEvaluationType = evaluation => {
  return selectedEvaluationType.value && selectedEvaluationType.value !== get(evaluation, 'evaluationType.id')
}

const showSelectedInstructor = evaluation => {
  return get(selectedInstructor.value, 'uid') && selectedInstructor.value.uid !== get(evaluation, 'instructor.uid')
}

const showSelectedStartDate = evaluation => {
  return selectedStartDate.value && selectedStartDay.value !== toFormatFromISO(evaluation.startDate, 'o')
}

const showSelectedStatus = evaluation => {
  return selectedEvaluationStatus.value && selectedEvaluationStatus.value !== evaluation.status
}

const reset = () => {
  selectedEvaluations.value = reduce(useDepartmentStore().evaluations, (evaluations, e) => {
    if (e.isSelected) {
      evaluations.push(e)
    }
    return evaluations
  }, [])
  midtermFormEnabled.value = false
  selectedDepartmentForm.value = props.departmentForm
  selectedEvaluationStatus.value = props.evaluationStatus
  selectedEvaluationType.value = props.evaluationType
  selectedInstructor.value = props.instructor
  selectedStartDate.value = props.startDate
  isInstructorRequired.value = props.midtermFormAvailable
}

const selectInstructor = suggestion => {
  selectedInstructor.value = suggestion
  if (selectedInstructor.value) {
    selectedInstructor.value.emailAddress = selectedInstructor.value.email
    if (selectedInstructor.value.isSisInstructor === false) {
      isConfirmingNonSisInstructor.value = true
    }
  }
}
</script>

<style>
.bulk-action-form-input {
  width: 250px
}
.bulk-action-preview-table > div {
  margin-right: -15px !important;
}
</style>

<style scoped>
.bulk-action-courseName-col {
  max-width: 6rem;
  width: 6rem;
}
.bulk-action-courseNumber-col {
  max-width: 2.5rem;
  width: 2.5rem;
}
.bulk-action-departmentForm-col {
  max-width: 6rem;
  width: 6rem;
}
.bulk-action-evaluationType-col {
  max-width: 4rem;
  width: 4rem;
}
.bulk-action-instructor-col {
  max-width: 7.5rem;
  width: 7.5rem;
}
.bulk-action-preview {
  overflow-x: hidden;
  overflow-y: auto;
  scrollbar-gutter: stable;
}
.bulk-action-preview-caption {
  font-size: 16px;
  font-weight: 500;
}
.bulk-action-preview-table {
  max-height: 200px;
}
.bulk-action-startDate-col {
  max-width: 65px;
  padding-right: 18px !important;
  width: 65px;
}
.bulk-action-status-col {
  max-width: 3rem;
  padding-left: 16px !important;
  width: 3rem;
}
</style>
