<template>
  <div class="align-center d-flex flex-wrap">
    <div class="mr-3">
      <label
        id="select-term-label"
        for="select-term"
        class="sr-only"
      >
        Term:
      </label>
      <select
        id="select-term"
        v-model="model"
        class="font-size-18 select-term my-2"
        :disabled="contextStore.loading"
        @change="onChangeTerm"
      >
        <option
          v-for="term in contextStore.config.availableTerms"
          :id="`term-option-${term.id}`"
          :key="term.id"
          :disabled="termIds && !includes(termIds, term.id)"
          :value="term.id"
        >
          {{ term.name }}
        </option>
      </select>
    </div>
    <div>
      <label for="toggle-term-locked" class="sr-only">
        Evaluation term is {{ contextStore.isSelectedTermLocked ? 'locked' : 'unlocked' }}.
      </label>
      <v-btn
        id="toggle-term-locked"
        class="px-0"
        :disabled="isTogglingLock || contextStore.loading"
        icon
        @click="toggleTermLocked"
      >
        <span class="sr-only">
          {{ isTogglingLock ? 'Toggling...' : (contextStore.isSelectedTermLocked ? 'Unlock' : 'Lock') }}
        </span>
        <v-progress-circular
          v-if="isTogglingLock"
          class="spinner"
          color="primary"
          :indeterminate="true"
          rotate="5"
          size="24"
          width="4"
        />
        <v-icon
          v-if="!isTogglingLock"
          :color="contextStore.isSelectedTermLocked ? 'error' : 'success'"
          :icon="contextStore.isSelectedTermLocked ? mdiLock : mdiLockOpen"
          size="large"
        />
      </v-btn>
    </div>
  </div>
</template>

<script setup>
import {alertScreenReader, putFocusNextTick} from '@/lib/utils'
import {computed, ref} from 'vue'
import {includes} from 'lodash'
import {lockEvaluationTerm, unlockEvaluationTerm} from '@/api/evaluationTerms'
import {mdiLock, mdiLockOpen} from '@mdi/js'
import {useContextStore} from '@/stores/context'
import {useRoute, useRouter} from 'vue-router'

const props = defineProps({
  afterSelect: {
    default: () => {},
    required: false,
    type: Function
  },
  termIds: {
    default: null,
    required: false,
    type: Array
  }
})

const contextStore = useContextStore()
const isTogglingLock = ref(false)
const query = useRoute().query
const router = useRouter()

const model = computed({
  get() {
    return contextStore.selectedTermId
  },
  set(termId) {
    contextStore.setSelectedTerm(termId)
    props.afterSelect()
  }
})

const onChangeTerm = event => {
  const termId = event.target.value
  if (termId && termId !== query.term) {
    contextStore.selectTerm(termId)
    router.push({
      query: {...query, term: termId}
    })
    putFocusNextTick('select-term')
  }
}

const toggleTermLocked = () => {
  isTogglingLock.value = true
  if (!contextStore.isSelectedTermLocked) {
    lockEvaluationTerm(contextStore.selectedTermId).then(data => {
      contextStore.setIsSelectedTermLocked(data.isLocked === true)
      alertScreenReader(`Locked ${contextStore.selectedTermName}`)
      putFocusNextTick('toggle-term-locked')
      isTogglingLock.value = false
    })
  } else {
    unlockEvaluationTerm(contextStore.selectedTermId).then(data => {
      contextStore.setIsSelectedTermLocked(data.isLocked === true)
      alertScreenReader(`Unlocked ${contextStore.selectedTermName}`)
      putFocusNextTick('toggle-term-locked')
      isTogglingLock.value = false
    })
  }
}
</script>

<style scoped>
.select-term {
  max-width: 200px;
}
</style>
