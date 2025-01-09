<template>
  <div
    id="screen-reader-alert"
    class="sr-only"
    :aria-live="contextStore.screenReaderAlert.politeness"
  >
    {{ contextStore.screenReaderAlert.message }}
  </div>
  <router-view />
</template>

<script setup>
import {useContextStore} from '@/stores/context'

const contextStore = useContextStore()
</script>

<style>
  @import './assets/styles/damien-global.css';
  @import 'v-calendar/style.css';
  @import "@/assets/styles/vcalendar-custom.css";
</style>
