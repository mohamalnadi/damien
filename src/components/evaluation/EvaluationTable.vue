<template>
  <div v-if="evaluations.length > 0">
    <div
      class="bg-surface-variant elevation-2 sticky"
      role="search"
    >
      <div class="align-start d-flex flex-wrap justify-start px-5 pt-3" :class="{'pb-2': readonly}">
        <v-text-field
          id="evaluation-search-input"
          v-model="searchFilter"
          aria-label="Filter evaluations table by search terms."
          class="evaluation-search-input mr-3"
          clearable
          color="tertiary"
          hide-details
          label="Filter courses"
          max-width="600px"
          type="search"
        />
        <AddCourseSection
          v-if="!readonly"
          id="add-course-section"
          :evaluations="evaluations"
          :allow-edits="allowEdits"
        />
      </div>
      <div class="align-center d-flex flex-wrap justify-space-between px-5">
        <div v-if="!readonly && allowEdits" class="d-flex">
          <div>
            <v-checkbox
              id="select-all-evals-checkbox"
              class="select-all-evals align-center mt-0 pt-0"
              color="tertiary"
              density="compact"
              :disabled="!searchFilterResults.length"
              :false-value="!someEvaluationsSelected && !allEvaluationsSelected"
              hide-details
              :indeterminate="someEvaluationsSelected"
              :input-value="someEvaluationsSelected || allEvaluationsSelected"
              :model-value="allEvaluationsSelected"
              :ripple="false"
              @change="toggleSelectAll"
            >
              <template #label>
                <span
                  v-if="!someEvaluationsSelected && !allEvaluationsSelected"
                  class="text-no-wrap pl-1 py-2"
                  :class="{'sr-only': someEvaluationsSelected || allEvaluationsSelected}"
                >
                  {{ someEvaluationsSelected || allEvaluationsSelected ? 'Unselect' : 'Select' }} all
                </span>
              </template>
            </v-checkbox>
          </div>
          <div class="evaluation-actions">
            <EvaluationActions v-if="!readonly" />
          </div>
        </div>
        <div class="align-center d-flex flex-wrap py-2">
          <div class="mr-2">Show statuses:</div>
          <v-btn-toggle
            v-model="selectedFilterTypes"
            aria-controls="evaluation-table"
            borderless
            class="status-filter"
            color="primary"
            density="compact"
            flat
            multiple
            rounded
          >
            <v-btn
              v-for="status in keys(filterTypes)"
              :id="`evaluations-filter-${status}`"
              :key="status"
              :active="filterTypes[status].enabled"
              :aria-selected="filterTypes[status].enabled"
              color="primary"
              class="mr-1 rounded-pill text-uppercase"
              height="30"
              size="small"
              :value="status"
              :width="filterTypes[status].width"
            >
              <div class="align-center d-flex justify-space-between">
                <v-icon
                  v-if="filterTypes[status].enabled"
                  color="success"
                  :icon="filterTypes[status].enabled ? mdiCheckCircle : mdiPlusCircle"
                  left
                />
                <div class="pl-1">
                  <span class="sr-only">{{ filterTypes[status].enabled ? 'Hide' : 'Show' }} evaluations of marked with</span>
                  {{ filterTypes[status].label }}
                </div>
                <div :class="filterTypes[status].enabled ? 'text-white' : 'text-grey darken-2'">
                  <v-chip
                    class="ml-2 px-1"
                    :class="{'font-weight-bold': filterTypes[status].enabled}"
                    size="x-small"
                  >
                    {{ filterTypeCounts(status) }}<span class="sr-only"> evaluations</span>
                  </v-chip>
                </div>
              </div>
            </v-btn>
          </v-btn-toggle>
        </div>
      </div>
    </div>
    <div
      id="evaluation-table-search-results-desc"
      aria-atomic="true"
      aria-live="polite"
      class="sr-only"
    >
      <span v-if="searchFilter">{{ pluralize('evaluation', size(searchFilterResults.value)) }} displayed.</span>
    </div>
    <v-data-table
      id="evaluation-table"
      v-model:sort-by="sortBy"
      aria-label="Evaluations"
      class="v-table-hidden-row-override pt-3"
      :custom-filter="customFilter"
      density="compact"
      :headers="evaluationHeaders"
      hide-default-footer
      :items="visibleEvaluations"
      items-per-page="-1"
      :loading="contextStore.loading"
      must-sort
      :search="searchFilter"
      :sort-by="sortBy"
      @update:sort-by="onSort"
      @update:current-items="onChangeSearchFilter"
    >
      <template #headers="{columns, isSorted, toggleSort, getSortIcon, sortBy: _sortBy}">
        <SortableTableHeader
          :columns="columns"
          :is-sorted="isSorted"
          :on-sort="toggleSort"
          :sort-desc="get(_sortBy, 'order') === 'desc'"
          :sort-icon="getSortIcon"
        />
      </template>
      <template #body="{items}">
        <TransitionGroup v-if="size(items)">
          <template v-for="(evaluation, rowIndex) in items" :key="evaluation.id">
            <tr
              class="evaluation-row"
              :class="{
                'evaluation-row-confirmed': evaluation.id !== editRowId && evaluation.status === 'confirmed',
                'evaluation-row-ignore text-muted': hoverId !== evaluation.id && evaluation.id !== editRowId && evaluation.status === 'ignore',
                'bg-secondary text-white border-bottom-none': evaluation.id === editRowId,
                'evaluation-row-review': evaluation.id !== editRowId && evaluation.status === 'review',
                'evaluation-row-xlisting': evaluation.id !== editRowId && !evaluation.status && (evaluation.crossListedWith || evaluation.roomSharedWith),
                'bg-primary-contrast text-primary': [focusedEditButtonEvaluationId, hoverId].includes(evaluation.id) && !isEditing(evaluation)
              }"
              @mouseenter="() => hoverId = evaluation.id"
              @mouseleave="() => hoverId = null"
            >
              <td v-if="readonly" :id="`evaluation-${rowIndex}-department`" class="align-middle py-1 pl-2">
                <router-link :to="`/department/${get(evaluation.department, 'id')}`">
                  {{ get(evaluation.department, 'name') }}
                </router-link>
              </td>
              <td
                v-if="!readonly && allowEdits && !(allowEdits && isEditing(evaluation))"
                :id="`evaluation-${rowIndex}-select`"
                class="align-middle text-center pr-1 pl-2"
              >
                <v-checkbox
                  v-if="!isEditing(evaluation)"
                  :id="`evaluation-${rowIndex}-checkbox`"
                  :aria-label="`${evaluation.subjectArea} ${evaluation.catalogId} ${selectedEvaluationIds.includes(evaluation.id) ? '' : 'not '}selected`"
                  class="pr-1"
                  :color="`${hoverId === evaluation.id ? 'primary' : 'tertiary'}`"
                  :disabled="editRowId === evaluation.id"
                  hide-details
                  :model-value="evaluation.isSelected"
                  :ripple="false"
                  @update:model-value="() => departmentStore.toggleSelectEvaluation(evaluation)"
                />
              </td>
              <td
                :id="`evaluation-${rowIndex}-status`"
                :class="{'align-middle position-relative': !isEditing(evaluation)}"
                class="px-1"
                :colspan="allowEdits && isEditing(evaluation) ? 2 : 1"
              >
                <div
                  v-if="isStatusVisible(evaluation)"
                  class="pill mx-auto"
                  :class="{
                    'pill-confirmed': evaluation.status === 'confirmed',
                    'pill-ignore': evaluation.status === 'ignore',
                    'pill-review': evaluation.status === 'review',
                    'sr-only': hoverId === evaluation.id && allowEdits && !readonly
                  }"
                >
                  {{ displayStatus(evaluation) }}
                </div>
                <div
                  v-if="allowEdits && !isEditing(evaluation) && (!readonly || !evaluation.status)"
                  class="pill pill-invisible mx-auto"
                >
                  <v-btn
                    :id="`edit-evaluation-${evaluation.id}-btn`"
                    class="text-uppercase"
                    :class="{'sr-only': ![focusedEditButtonEvaluationId, hoverId].includes(evaluation.id), 'focus-btn': evaluation.id === focusedEditButtonEvaluationId}"
                    color="primary"
                    block
                    :disabled="!allowEdits"
                    text="Edit"
                    variant="text"
                    @blur="() => focusedEditButtonEvaluationId = null"
                    @click="() => onEditEvaluation(evaluation)"
                    @focus="() => focusedEditButtonEvaluationId = evaluation.id"
                  />
                </div>
                <div v-if="allowEdits && isEditing(evaluation)" class="pl-2 py-2 select-evaluation-status">
                  <label for="select-evaluation-status">
                    Status:
                  </label>
                  <select
                    id="select-evaluation-status"
                    v-model="selectedEvaluationStatus"
                    class="d-block mx-auto bg-white v-theme--light w-99"
                    :disabled="isSaving"
                  >
                    <option
                      v-if="!selectedEvaluationStatus"
                      selected
                      :value="selectedEvaluationStatus"
                    >
                      Select...
                    </option>
                    <option
                      v-for="s in EVALUATION_STATUSES"
                      :key="s.text"
                      :selected="selectedEvaluationStatus === s.value"
                      :value="s.value"
                    >
                      {{ s.text }}
                    </option>
                  </select>
                </div>
              </td>
              <td
                :id="`evaluation-${rowIndex}-lastUpdated`"
                class="align-middle evaluation-last-updated px-1"
                :class="{'font-weight-bold pt-5': isEditing(evaluation)}"
              >
                {{ toFormatFromJsDate(evaluation.lastUpdated, 'LL/dd/yyyy') }}
              </td>
              <td
                :id="`evaluation-${rowIndex}-courseNumber`"
                class="align-middle evaluation-course-number px-1"
                :class="{'font-weight-bold pt-5': isEditing(evaluation)}"
              >
                {{ evaluation.courseNumber }}
                <div v-if="evaluation.crossListedWith" class="xlisting-note">
                  (Cross-listed with {{ evaluation.crossListedWith.length > 1 ? 'sections' : 'section' }}
                  {{ evaluation.crossListedWith.join(', ') }})
                </div>
                <div v-if="evaluation.roomSharedWith" class="xlisting-note">
                  (Room shared with {{ evaluation.roomSharedWith.length > 1 ? 'sections' : 'section' }}
                  {{ evaluation.roomSharedWith.join(', ') }})
                </div>
              </td>
              <td
                class="evaluation-course-name px-1"
                :class="{
                  'font-weight-bold pt-5': isEditing(evaluation),
                  'align-middle': !isEditing(evaluation),
                  'pt-2': !evaluation.instructor && isEditing(evaluation) && allowEdits
                }"
              >
                <label :id="`evaluation-${rowIndex}-courseName`" :for="isEditing(evaluation) ? undefined : `evaluation-${rowIndex}-checkbox`">
                  {{ evaluation.subjectArea }}
                  {{ evaluation.catalogId }}
                  {{ evaluation.instructionFormat }}
                  {{ evaluation.sectionNumber }}
                </label>
                <div :id="`evaluation-${rowIndex}-courseTitle`">
                  {{ evaluation.courseTitle }}
                </div>
              </td>
              <td
                :id="`evaluation-${rowIndex}-instructor`"
                class="evaluation-instructor px-1"
                :class="{'font-weight-bold py-2': isEditing(evaluation), 'align-middle': !isEditing(evaluation)}"
              >
                <div v-if="evaluation.instructor">
                  {{ evaluation.instructor.firstName }}
                  {{ evaluation.instructor.lastName }}
                  ({{ evaluation.instructor.uid }})
                </div>
                <div v-if="evaluation.instructor">
                  {{ evaluation.instructor.emailAddress }}
                </div>
                <EvaluationError
                  v-if="!evaluation.instructor && !isEditing(evaluation) && (evaluation.status === 'review' || evaluation.status === 'confirmed')"
                  id="error-msg-evaluation-instructor"
                  :hover="[focusedEditButtonEvaluationId, hoverId].includes(evaluation.id)"
                  message="Instructor required"
                />
                <div v-if="!evaluation.instructor && isEditing(evaluation) && allowEdits" class="position-relative">
                  <PersonLookup
                    class="font-weight-regular instructor-lookup"
                    :disabled="isSaving"
                    input-class="text-no-wrap overflow-hidden"
                    :instructor-lookup="true"
                    label="Instructor"
                    list-label="Suggested Instructors List"
                    :on-select-result="selectInstructor"
                    variant="solo"
                  />
                  <div v-if="pendingInstructor" class="position-absolute pt-1">
                    <div>
                      {{ pendingInstructor.firstName }} {{ pendingInstructor.lastName }} ({{ pendingInstructor.uid }})
                    </div>
                    <div>
                      {{ pendingInstructor.emailAddress }}
                    </div>
                  </div>
                </div>
              </td>
              <td
                :id="`evaluation-${rowIndex}-departmentForm`"
                class="evaluation-department-form px-1"
                :class="{'align-middle': !isEditing(evaluation), 'py-2': isEditing(evaluation)}"
              >
                <div v-if="evaluation.departmentForm && !isEditing(evaluation)">
                  {{ evaluation.departmentForm.name }}
                  <EvaluationError
                    v-for="(conflict, index) in evaluation.conflicts.departmentForm"
                    :id="`error-msg-evaluation-department-form-conflict-${index}`"
                    :key="index"
                    :hover="[focusedEditButtonEvaluationId, hoverId].includes(evaluation.id)"
                    :message="`Conflicts with value ${conflict.value} from ${conflict.department} department`"
                  />
                </div>
                <EvaluationError
                  v-if="!evaluation.departmentForm && !isEditing(evaluation) && (evaluation.status === 'review' || evaluation.status === 'confirmed')"
                  id="error-msg-evaluation-department-form"
                  :hover="[focusedEditButtonEvaluationId, hoverId].includes(evaluation.id)"
                  message="Department form required"
                />
                <div v-if="allowEdits && isEditing(evaluation)">
                  <label id="select-department-form-label" for="select-department-form">
                    Department Form:
                  </label>
                  <select
                    id="select-department-form"
                    v-model="selectedDepartmentForm"
                    class="bg-white v-theme--light"
                    :disabled="isSaving"
                  >
                    <option v-for="df in departmentForms" :key="df.id" :value="df.id">{{ df.name }}</option>
                  </select>
                </div>
              </td>
              <td
                :id="`evaluation-${rowIndex}-evaluationType`"
                class="evaluation-type px-1"
                :class="{'align-middle': !isEditing(evaluation), 'py-2': isEditing(evaluation)}"
              >
                <div v-if="evaluation.evaluationType && !isEditing(evaluation)">
                  {{ evaluation.evaluationType.name }}
                  <EvaluationError
                    v-for="(conflict, index) in evaluation.conflicts.evaluationType"
                    :id="`error-msg-evaluation-type-conflict-${index}`"
                    :key="index"
                    :hover="[focusedEditButtonEvaluationId, hoverId].includes(evaluation.id)"
                    :message="`Conflicts with value ${conflict.value} from ${conflict.department} department`"
                  />
                </div>
                <EvaluationError
                  v-if="!evaluation.evaluationType && !isEditing(evaluation) && (evaluation.status === 'review' || evaluation.status === 'confirmed')"
                  id="error-msg-evaluation-type"
                  :hover="[focusedEditButtonEvaluationId, hoverId].includes(evaluation.id)"
                  message="Evaluation type required"
                />
                <div v-if="allowEdits && isEditing(evaluation)">
                  <label id="select-evaluation-type-label" for="select-evaluation-type">
                    Evaluation Type:
                  </label>
                  <select
                    id="select-evaluation-type"
                    v-model="selectedEvaluationType"
                    class="bg-white v-theme--light"
                    :disabled="isSaving"
                  >
                    <option
                      v-if="!selectedEvaluationType"
                      selected
                      :value="selectedEvaluationType"
                    >
                      Select...
                    </option>
                    <option
                      v-for="et in evaluationTypes"
                      :key="et.id"
                      :selected="selectedEvaluationType === et.id"
                      :value="et.id"
                    >
                      {{ et.name }}
                    </option>
                  </select>
                </div>
              </td>
              <td
                :id="`evaluation-${rowIndex}-period`"
                class="evaluation-period px-1"
                :class="{'align-middle': !isEditing(evaluation), 'py-2': isEditing(evaluation)}"
              >
                <div v-if="evaluation.startDate && !isEditing(evaluation)">
                  <div class="text-no-wrap">
                    {{ toFormatFromJsDate(evaluation.startDate, 'LL/dd/yyyy') }} -
                    {{ toFormatFromJsDate(evaluation.endDate, 'LL/dd/yyyy') }}
                  </div>
                  <div>{{ evaluation.modular ? 2 : 3 }} weeks</div>
                  <EvaluationError
                    v-for="(conflict, index) in evaluation.conflicts.evaluationPeriod"
                    :id="`error-msg-evaluation-period-conflict-${index}`"
                    :key="index"
                    :hover="[focusedEditButtonEvaluationId, hoverId].includes(evaluation.id)"
                    :message="`Conflicts with period starting
                    ${toLocaleFromISO(conflict.value, 'LL/dd/yyyy')}
                    from ${conflict.department} department`"
                  />
                </div>
                <div v-if="allowEdits && isEditing(evaluation)" class="evaluation-period-edit">
                  <label for="evaluation-start-date-input">
                    Start date:
                  </label>
                  <AccessibleDateInput
                    aria-label="Select Date"
                    :container-id="`evaluation-${rowIndex}-period`"
                    :disabled="isSaving"
                    :get-value="() => selectedStartDate"
                    id-prefix="evaluation-start-date"
                    :min-date="minStartDate(evaluation)"
                    :max-date="evaluation.maxStartDate"
                    :set-value="selectedDate => selectedStartDate = selectedDate"
                  />
                </div>
              </td>
            </tr>
            <tr v-if="isEditing(evaluation)" :key="`${evaluation.id}-edit`" class="bg-secondary text-white border-top-none">
              <td></td>
              <td :colspan="size(evaluationHeaders) - 1" class="pb-1 px-3">
                <div class="d-flex justify-end">
                  <ConfirmDialog
                    v-if="markAsDoneWarning"
                    confirm-button-label="Proceed"
                    :disabled="disableControls"
                    :on-click-cancel="() => markAsDoneWarning = undefined"
                    :on-click-confirm="onProceedMarkAsDone"
                    :text="markAsDoneWarning.message"
                    :icon="mdiAlertCircle"
                    title="Warning"
                  />
                  <ProgressButton
                    id="save-evaluation-edit-btn"
                    :action="() => validateAndSave(evaluation)"
                    class="ma-2 evaluation-form-btn"
                    :disabled="disableControls || !rowValid || isSaving"
                    :in-progress="isSaving"
                    :text="isSaving ? 'Saving...' : 'Save'"
                  />
                  <v-btn
                    id="cancel-evaluation-edit-btn"
                    class="evaluation-form-btn ma-2 text-primary"
                    :disabled="isSaving"
                    text="Cancel"
                    variant="flat"
                    @click="onCancelEdit(evaluation)"
                  />
                </div>
              </td>
            </tr>
          </template>
        </TransitionGroup>
        <tr v-if="isEmpty(items)">
          <td :colspan="size(evaluationHeaders)">
            <div id="no-courses-found" class="d-flex font-weight-medium font-size-16 justify-center pa-5">
              <v-icon class="mr-1" color="error" :icon="mdiAlert" />
              {{ searchFilter ? 'No courses match your filter.' : 'No courses found.' }}
            </div>
          </td>
        </tr>
      </template>
    </v-data-table>
    <ConfirmDialog
      v-if="isConfirmingCancelEdit"
      :disabled="disableControls"
      :on-click-cancel="onCancelConfirm"
      :on-click-confirm="onConfirm"
      :text="'You have unsaved changes that will be lost.'"
      :title="'Cancel edit?'"
    />
    <ConfirmDialog
      v-if="isConfirmingNonSisInstructor"
      :disabled="disableControls"
      :on-click-cancel="onCancelNonSisInstructor"
      :on-click-confirm="onConfirmNonSisInstructor"
      :text="instructorConfirmationText(pendingInstructor)"
      title="Add new instructor?"
    />
    <v-dialog
      id="error-dialog"
      v-model="errorDialog"
      role="alertdialog"
      aria-labelledby="error-dialog-title"
      aria-describedby="error-dialog-text"
    >
      <v-card class="modal-content" width="400">
        <v-card-title id="error-dialog-title">Error</v-card-title>
        <v-card-text id="error-dialog-text" class="pt-3">{{ errorDialogText }}</v-card-text>
        <v-divider />
        <v-card-actions>
          <v-spacer />
          <div class="pa-2">
            <v-btn
              id="error-dialog-ok-btn"
              class="mr-2"
              color="primary"
              text="OK"
              variant="flat"
              @click="departmentStore.dismissErrorDialog"
            />
          </div>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
  <v-container v-else class="no-eligible-sections py-8">
    <v-row>
      <v-col align-self="center">
        <div class="d-flex flex-column text-muted">
          <span>No eligible sections to load.</span>
          <span v-if="!readonly && allowEdits">You may still add a section manually.</span>
        </div>
      </v-col>
    </v-row>
    <v-row v-if="!readonly">
      <v-col align-self="center">
        <AddCourseSection
          id="add-course-section"
          :evaluations="evaluations"
          :allow-edits="allowEdits"
          class="d-flex align-baseline justify-center ml-0"
        />
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup>
import AccessibleDateInput from '@/components/util/AccessibleDateInput'
import AddCourseSection from '@/components/evaluation/AddCourseSection'
import ConfirmDialog from '@/components/util/ConfirmDialog'
import EvaluationActions from '@/components/evaluation/EvaluationActions'
import EvaluationError from '@/components/evaluation/EvaluationError'
import PersonLookup from '@/components/admin/PersonLookup'
import ProgressButton from '@/components/util/ProgressButton.vue'
import SortableTableHeader from '@/components/util/SortableTableHeader'
import {addInstructor} from '@/api/instructor'
import {alertScreenReader, oxfordJoin, pluralize, putFocusNextTick, toFormatFromJsDate, toLocaleFromISO} from '@/lib/utils'
import {clone, cloneDeep, each, filter, find, get, includes, isEmpty, keys, map, pickBy, size, some} from 'lodash'
import {computed, nextTick, onMounted, ref, watch} from 'vue'
import {EVALUATION_STATUSES, useDepartmentStore} from '@/stores/department/department-edit-session'
import {mdiAlert, mdiAlertCircle, mdiCheckCircle, mdiPlusCircle} from '@mdi/js'
import {storeToRefs} from 'pinia'
import {useContextStore} from '@/stores/context'
import {validateMarkAsDone} from '@/stores/department/utils'

const props = defineProps({
  readonly: {
    type: Boolean,
    required: false
  }
})

const contextStore = useContextStore()
const departmentStore = useDepartmentStore()
const {disableControls, errorDialog, errorDialogText, evaluations, selectedEvaluationIds} = storeToRefs(departmentStore)
const departmentForms = ref([])
const editRowId = ref(undefined)
const evaluationHeaders = ref([])
const evaluationTypes = ref([])
const filterTypes = {
  unmarked: {label: 'None', enabled: true, width: 112},
  review: {label: 'To-Do', enabled: true, width: 114},
  confirmed: {label: 'Done', enabled: true, width: 112},
  ignore: {label: 'Ignore', enabled: false, width: 122}
}
const focusedEditButtonEvaluationId = ref(undefined)
const hoverId = ref(undefined)
const isConfirmingCancelEdit = ref(false)
const isConfirmingNonSisInstructor = ref(false)
const isSaving = ref(false)
const markAsDoneWarning = ref(undefined)
const pendingEditRowId = ref(undefined)
const pendingInstructor = ref(undefined)
const rules = {
  instructorUid: undefined
}
const searchFilter = ref('')
const searchFilterResults = ref([])
const selectedDepartmentForm = ref(undefined)
const selectedEvaluationStatus = ref(undefined)
const selectedEvaluationType = ref(undefined)
const selectedFilterTypes = ref(keys(pickBy(filterTypes, 'enabled')))
const selectedStartDate = ref(undefined)
const sortBy = ref([{key: 'sortableCourseName', order: 'asc'}])

const allEvaluationsSelected = computed(() => {
  const selectedCount = size(selectedEvaluationIds.value)
  return !!selectedCount && selectedCount === size(evaluations.value)
})
const allowEdits = computed(() => {
  return contextStore.currentUser.isAdmin || !contextStore.isSelectedTermLocked
})
const rowValid = computed(() => {
  const evaluation = find(evaluations.value, ['id', editRowId.value])
  return selectedStartDate.value >= minStartDate(evaluation) && selectedStartDate.value <= evaluation.maxStartDate
})
const someEvaluationsSelected = computed(() => {
  const selectedCount = size(selectedEvaluationIds.value)
  return !!selectedCount && selectedCount < size(evaluations.value)
})
const visibleEvaluations = computed(() => {
  return filter(evaluations.value, isStatusFilterEnabled)
})

watch(errorDialog, isOpen => {
  if (isOpen) {
    putFocusNextTick('error-dialog-ok-btn')
  }
})

watch(selectedFilterTypes, types => {
  alertScreenReader(`Showing ${types.length ? `evaluations marked ${oxfordJoin(types)}` : 'no evaluations'}`)
  each(keys(filterTypes), type => {
    filterTypes[type].enabled = types.includes(type)
  })
})

onMounted(() => {
  evaluationHeaders.value = [
    {key: 'status', class: 'pl-4 pr-1 text-no-wrap', headerProps: {justifyItems: 'center', minWidth: '115px', width: '10%'}, sortable: true, title: 'Status', value: 'status'},
    {key: 'lastUpdated', class: 'px-1 text-no-wrap', headerProps: {width: '5%'}, sortable: true, title: 'Last Updated', value: 'lastUpdated'},
    {key: 'courseNumber', class: 'px-1 text-no-wrap', headerProps: {width: '5%'}, sortable: true, title: 'Course Number', value: 'sortableCourseNumber'},
    {key: 'courseName', class: 'px-1 course-name', headerProps: {width: '20%'}, sortable: true, title: 'Course Name', value: 'sortableCourseName'},
    {key: 'instructor', class: 'px-1 text-no-wrap', headerProps: {width: '20%'}, sortable: true, title: 'Instructor', value: 'sortableInstructor'},
    {key: 'departmentForm', class: 'px-1 text-start', headerProps: {width: '10%'}, sortable: true, title: 'Department Form', value: 'departmentForm.name'},
    {key: 'evaluationType', class: 'px-1 text-start', headerProps: {width: '10%'}, sortable: true, title: 'Evaluation Type', value: 'evaluationType.name'},
    {key: 'startDate', class: 'px-1 text-no-wrap', headerProps: {width: '15%'}, sortable: true, title: 'Evaluation Period', value: 'startDate'}
  ]
  if (props.readonly) {
    evaluationHeaders.value.unshift({key: 'departmentId', class: 'text-no-wrap pl-2 pr-1', sortable: true, title: 'Department', value: 'department.id'})
  } else if (allowEdits.value) {
    evaluationHeaders.value.unshift(
      {key: 'select', class: 'text-no-wrap pl-2 pr-1', headerProps: {justifyItems: 'center', width: '5%'}, sortable: true, title: 'Select', value: 'isSelected'}
    )
  }
  departmentForms.value = [{id: null, name: 'Revert'}].concat(departmentStore.activeDepartmentForms)
  evaluationTypes.value = [{id: null, name: 'Revert'}].concat(contextStore.config.evaluationTypes)

  rules.instructorUid = () => {
    return get(pendingInstructor.value, 'uid') ? true : 'Instructor is required.'
  }
})

const afterEditEvaluation = evaluation => {
  if (pendingInstructor.value && pendingInstructor.value.isSisInstructor === false) {
    addInstructor(pendingInstructor.value)
  }
  editRowId.value = null
  pendingEditRowId.value = null
  pendingInstructor.value = null
  isSaving.value = false
  selectedDepartmentForm.value = null
  selectedEvaluationStatus.value = null
  selectedEvaluationType.value = null
  selectedStartDate.value = null
  focusedEditButtonEvaluationId.value = evaluation.id
  putFocusNextTick(`edit-evaluation-${focusedEditButtonEvaluationId.value}-btn`)
}

const customFilter = (value, search, item) => {
  if (!search) {
    return true
  }
  if (!value || typeof value === 'boolean') {
    return false
  }
  if (value === item.sortableInstructor) {
    value = item.searchableInstructor
  }
  if (value === item.lastUpdated) {
    value = toLocaleFromISO(item.lastUpdated, 'LL/dd/yyyy')
  }
  if (value === item.sortableCourseName) {
    value = item.searchableCourseName
  }
  if (value === item.sortableCourseNumber) {
    value = item.courseNumber
    if (item.crossListedWith) {
      value += (' ' + item.crossListedWith.join(', '))
    }
    if (item.roomSharedWith) {
      value += (' ' + item.roomSharedWith.join(', '))
    }
  }
  if (value === item.startDate) {
    value = [
      toLocaleFromISO(item.startDate, 'LL/dd/yyyy'),
      '-',
      toLocaleFromISO(item.endDate, 'LL/dd/yyyy'),
      (item.modular ? '2' : '3'),
      'weeks'
    ].join(' ')
  }
  return value.toString().toLocaleLowerCase().indexOf(search.toLocaleLowerCase()) !== -1
}

const displayStatus = evaluation => {
  if (evaluation.status === 'review') {
    return 'To Do'
  } else if (evaluation.status === 'confirmed') {
    return 'Done'
  } else {
    return evaluation.status
  }
}

const filterTypeCounts = type => {
  if (type === 'unmarked') {
    return filter(evaluations.value, e => e.status === null).length
  }
  return filter(evaluations.value, e => e.status === type).length
}

const instructorConfirmationText = instructor => {
  return `
    ${instructor.firstName} ${instructor.lastName} (${instructor.uid})
    is not currently listed in SIS data as an instructor for any courses.`
}

const isEditing = evaluation => {
  return editRowId.value === evaluation.id
}

const isStatusFilterEnabled = evaluation => {
  const status = evaluation.status || 'unmarked'
  return includes(selectedFilterTypes.value, status)
}

const isStatusVisible = evaluation => {
  return !isEditing(evaluation)
    && evaluation.status
    && evaluation.id !== focusedEditButtonEvaluationId.value
}

const minStartDate = evaluation => {
  return new Date(get(evaluation, 'meetingDates.start'))
}

const onCancelConfirm = () => {
  isConfirmingCancelEdit.value = false
  focusedEditButtonEvaluationId.value = clone(pendingEditRowId.value)
  pendingEditRowId.value = null
  putFocusNextTick(`edit-evaluation-${focusedEditButtonEvaluationId.value}-btn`)
}

const onCancelEdit = evaluation => {
  alertScreenReader('Edit canceled.')
  afterEditEvaluation(evaluation)
}

const onCancelNonSisInstructor = () => {
  isConfirmingNonSisInstructor.value = false
  pendingInstructor.value = null
}

const onChangeSearchFilter = filterResults => {
  if (!contextStore.loading) {
    searchFilterResults.value = map(filterResults, r => r.raw)
    if (size(selectedEvaluationIds.value)) {
      departmentStore.filterSelectedEvaluations(searchFilterResults.value, selectedFilterTypes.value)
    }
    if (!some(searchFilterResults.value, {'id': editRowId.value})) {
      editRowId.value = null
    }
  }
}

const onConfirm = () => {
  const evaluation = find(evaluations.value, ['id', pendingEditRowId.value])
  isConfirmingCancelEdit.value = false
  editRowId.value = null
  onEditEvaluation(evaluation)
}

const onConfirmNonSisInstructor = () => {
  isConfirmingNonSisInstructor.value = false
}

const onEditEvaluation = evaluation => {
  if (editRowId.value) {
    const editingEvaluation = find(evaluations.value, ['id', editRowId.value])
    isConfirmingCancelEdit.value = editingEvaluation && (
      get(pendingInstructor.value, 'uid') !== get(editingEvaluation, 'instructor.uid')
      || selectedDepartmentForm.value !== get(editingEvaluation, 'departmentForm.id')
      || selectedEvaluationStatus.value !== get(editingEvaluation, 'status')
      || selectedEvaluationType.value !== get(editingEvaluation, 'evaluationType.id')
      || selectedStartDate.value !== editingEvaluation.startDate
    )
  }
  if (isConfirmingCancelEdit.value) {
    pendingEditRowId.value = evaluation.id
  } else {
    editRowId.value = evaluation.id
    pendingInstructor.value = evaluation.instructor
    selectedDepartmentForm.value = get(evaluation, 'departmentForm.id')
    selectedEvaluationStatus.value = get(evaluation, 'status')
    selectedEvaluationType.value = get(evaluation, 'evaluationType.id')
    selectedStartDate.value = evaluation.startDate
    putFocusNextTick(`${props.readonly ? '' : 'select-evaluation-status'}`)
  }
}

const onProceedMarkAsDone = () => {
  const evaluation = markAsDoneWarning.value.evaluation
  const fields = markAsDoneWarning.value.fields
  markAsDoneWarning.value = undefined
  updateEvaluation(evaluation, fields)
}

const onSort = () => {
  nextTick(() => {
    const selectedEvalIds = cloneDeep(selectedEvaluationIds.value)
    departmentStore.setSelectedEvaluationIds(selectedEvalIds)
  })
}

const selectInstructor = instructor => {
  if (instructor) {
    instructor.emailAddress = instructor.email
    if (!instructor.isSisInstructor) {
      isConfirmingNonSisInstructor.value = true
    }
  }
  pendingInstructor.value = instructor
}

const toggleSelectAll = () => {
  if (allEvaluationsSelected.value || someEvaluationsSelected.value) {
    departmentStore.deselectAllEvaluations()
    alertScreenReader('All evaluations unselected')
  } else {
    alertScreenReader('All evaluations selected')
    departmentStore.selectAllEvaluations(searchFilterResults.value, selectedFilterTypes.value)
  }
}

const updateEvaluation = (evaluation, fields) => {
  isSaving.value = true
  alertScreenReader('Saving evaluation row.')
  return new Promise(resolve => {
    const showError = fields.status === 'confirmed' && (!fields.departmentFormId || !fields.evaluationTypeId || !fields.instructorUid)
    if (showError) {
      departmentStore.showErrorDialog('Cannot confirm an evaluation with missing fields.')
      isSaving.value = false
      resolve()
    } else {
      departmentStore.editEvaluation(
        evaluation.id,
        evaluation.courseNumber,
        contextStore.selectedTermId,
        fields
      ).then(() => {
        alertScreenReader('Changes saved.')
        isSaving.value = false
        afterEditEvaluation(evaluation)
        departmentStore.deselectAllEvaluations()
        resolve()
      }).catch(error => {
        departmentStore.showErrorDialog(get(error, 'response.data.message', 'An unknown error occurred.'))
        isSaving.value = false
        resolve()
      })
    }
  })
}

const validateAndSave = evaluation => {
  markAsDoneWarning.value = null
  const departmentFormId = selectedDepartmentForm.value || get(evaluation, 'defaultDepartmentForm.id') || null
  const status = selectedEvaluationStatus.value === 'none' ? null : selectedEvaluationStatus.value
  const startDate = selectedStartDate.value ? toFormatFromJsDate(selectedStartDate.value, 'y-LL-dd') : null
  const fields = {
    departmentFormId,
    evaluationTypeId: selectedEvaluationType.value,
    instructorUid: get(pendingInstructor.value, 'uid'),
    startDate,
    status
  }
  let warning
  if (status === 'confirmed') {
    // If evaluation start-date is in the past then put up a warning dialog.
    const proposedUpdate = {...evaluation, ...fields}
    warning = validateMarkAsDone([proposedUpdate])
  }
  if (warning) {
    markAsDoneWarning.value = {evaluation, fields, message: warning}
  } else {
    updateEvaluation(evaluation, fields)
  }
}
</script>

<style>
.course-name {
  min-width: 200px;
}
.evaluation-input .v-messages__message {
  color: #fff !important;
}
.focus-btn::before {
  opacity: 0.24;
}
tr.border-bottom-none td {
  border-bottom: none !important;
}
tr.border-top-none td {
  border-top: none !important;
}
</style>

<style scoped>
.align-middle {
  vertical-align: middle;
}
.evaluation-actions {
  position: relative;
  top: 2px;
}
.evaluation-course-name {
  min-width: 200px;
}
.evaluation-course-number {
  min-width: 115px;
}
.evaluation-department-form {
  min-width: 155px;
}
.evaluation-form-btn {
  width: 150px;
}
.evaluation-instructor {
  min-width: 175px;
}
.evaluation-last-updated {
  min-width: 100px;
}
.evaluation-period-edit {
  width: 166px;
  max-width: 166px;
}
.evaluation-row {
  vertical-align: top;
}
.evaluation-row.evaluation-row-enter-to {
  animation: 4s fadeOut;
  animation-timing-function: cubic-bezier(.05, -.12, .02, .32);
}
.evaluation-row.evaluation-row-enter-from,
.evaluation-row.evaluation-row-leave-to {
  opacity: 0;
  transform: translateX(50%);
}
.evaluation-row.evaluation-row-move,
.evaluation-row.evaluation-row-enter-active,
.evaluation-row.evaluation-row-leave-active {
  transition: opacity 0.5s ease,
    position 0.5s ease,
    transform 0.5s ease;
}
.evaluation-row.evaluation-row-leave-active {
  position: absolute;
}
.evaluation-search-input {
  max-width: 540px;
}
.evaluation-type {
  min-width: 145px;
}
.instructor-lookup {
  max-width: 300px !important;
  min-width: 168px !important;
}
.no-eligible-sections {
  font-size: 20px;
  height: fit-content;
}
.pill {
  border: 1px solid #999;
  border-radius: 5px;
  color: #fff;
  font-size: 0.8em;
  font-weight: bold;
  margin: 0;
  padding: 3px 10px;
  text-align: center;
  text-transform: uppercase;
  width: 90px;
}
.pill-confirmed {
  background-color: #176190;
}
.pill-ignore {
  background-color: #666;
}
.pill-invisible {
  border: none;
  padding: 0;
}
.pill-review {
  background-color: #478047;
}
.select-all-evals {
  height: 36px;
  width: 6.5rem;
}
.select-evaluation-status {
  width: 80%;
}
.status-filter {
  height: fit-content !important;
}
.sticky {
  position: sticky;
  top: 60px;
  z-index: 10;
}
.w-99 {
  width: 99%;
}
.xlisting-note {
  font-size: 0.8em;
}
</style>
