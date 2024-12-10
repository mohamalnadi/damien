<template>
  <a
    id="skip-to-content-link"
    href="#content"
    class="sr-only"
    tabindex="0"
  >
    Skip to main content
  </a>
  <v-layout ref="layout">
    <v-app-bar
      app
      clipped-left
      color="primary"
      dark
    >
      <div class="text-h4 ml-3 text-no-wrap">
        Course Evaluations
      </div>
      <div class="ml-auto pr-4">
        <v-menu offset-y rounded="lg">
          <template #activator="{props: menuProps}">
            <v-btn
              id="btn-main-menu"
              color="secondary"
              variant="flat"
              v-bind="menuProps"
            >
              <span class="sr-only">User profile for </span>{{ currentUser.firstName }}
            </v-btn>
          </template>
          <v-list density="comfortable">
            <v-list-item
              id="menu-item-log-out"
              :append-icon="mdiLogout"
              base-color="secondary"
              link
              @click="logOut"
            >
              <v-list-item-title class="font-weight-medium">Log Out</v-list-item-title>
            </v-list-item>
          </v-list>
        </v-menu>
      </div>
    </v-app-bar>
    <v-navigation-drawer
      aria-labelledby="nav-header"
      class="font-size-14 pt-2"
      color="secondary"
      permanent
      :rail="isSidebarCollapsed"
      rail-width="56"
      role="navigation"
      :scrim="false"
      tag="nav"
      width="220"
    >
      <template #prepend>
        <h2 id="nav-header" class="sr-only" tabindex="-1">Main Menu</h2>
      </template>
      <template #append>
        <div class="d-flex justify-end pa-2">
          <v-btn
            id="sidebar-toggle-btn"
            :aria-hidden="true"
            class="font-size-16 px-0"
            color="primary-contrast"
            variant="tonal"
            min-width="40"
            @click="toggleSidebarCollapsed"
          >
            <v-icon :icon="isSidebarCollapsed ? mdiArrowExpandRight : mdiArrowCollapseLeft" size="x-large" />
          </v-btn>
        </div>
      </template>
      <v-list-item
        v-for="(item, index) in navItems"
        :id="`sidebar-link-${item.id}`"
        :key="index"
        :aria-current="startsWith(route.path, item.path) ? 'page' : null"
        class="font-size-16"
        :class="{
          'py-4 px-3': isSidebarCollapsed,
          'pa-4': !isSidebarCollapsed,
          'bg-selected-nav-item': startsWith(route.path, item.path)
        }"
        :elevation="startsWith(route.path, item.path) ? 2 : 0"
        link
        role="link"
        @click="toRoute(item.path)"
      >
        <div class="align-center d-flex">
          <v-icon
            :class="startsWith(route.path, item.path) ? 'text-white' : 'text-primary-contrast'"
            :icon="item.icon"
            size="x-large"
            :title="isSidebarCollapsed ? item.title : undefined"
          />
          <div
            class="ml-4 nav-drawer-letter-spacing text-no-wrap"
            :class="startsWith(route.path, item.path) ? 'font-weight-bold text-white' : 'font-weight-medium text-primary-contrast'"
          >
            {{ item.title }}
          </div>
        </div>
      </v-list-item>
      <v-list-item
        :id="`sidebar-link-${size(navItems)}`"
        class="font-size-16"
        :class="{'py-4 px-3': isSidebarCollapsed, 'pa-4': !isSidebarCollapsed}"
        @click="toggleColorScheme"
      >
        <div class="align-center d-flex">
          <v-icon
            aria-label="Lightbulb icon"
            color="primary-contrast"
            :icon="theme.global.current.value.dark ? mdiLightbulb : mdiLightbulbOutline"
            size="x-large"
            :title="isSidebarCollapsed ? `${theme.global.current.value.dark ? 'Light' : 'Dark'} mode` : undefined"
          />
          <div class="font-weight-medium ml-4 nav-drawer-letter-spacing text-no-wrap text-primary-contrast" role="button">
            {{ theme.global.current.value.dark ? 'Light' : 'Dark' }} mode
          </div>
        </div>
      </v-list-item>
    </v-navigation-drawer>
    <v-main id="content" class="mb-4" :style="`--v-layout-bottom: ${footerHeight}px;`">
      <Snackbar />
      <Spinner v-if="contextStore.loading" />
      <div
        v-if="contextStore.serviceAnnouncement && contextStore.serviceAnnouncement.isLive"
        class="service-announcement"
      >
        <pre>
          <span
            id="service-announcement"
            v-linkified
            class="body-2"
            aria-live="polite"
            role="alert"
            v-html="contextStore.serviceAnnouncement.text"
          />
        </pre>
      </div>
      <router-view :key="stripAnchorRef(route.fullPath)" class="px-4" />
    </v-main>
    <DamienFooter />
  </v-layout>
</template>

<script setup>
import DamienFooter from '@/components/util/DamienFooter'
import Snackbar from '@/components/util/Snackbar'
import Spinner from '@/components/util/Spinner'
import {alertScreenReader, stripAnchorRef} from '@/lib/utils'
import {computed, onMounted, ref} from 'vue'
import {get, map, size, startsWith} from 'lodash'
import {getCasLogoutUrl} from '@/api/auth'
import {
  mdiAccountGroup,
  mdiAlertCircle,
  mdiArrowCollapseLeft,
  mdiArrowExpandRight,
  mdiLightbulb,
  mdiLightbulbOutline,
  mdiListStatus,
  mdiLogout,
  mdiPlaylistEdit
} from '@mdi/js'
import {useContextStore} from '@/stores/context'
import {useTheme} from 'vuetify'
import {useRoute, useRouter} from 'vue-router'

const contextStore = useContextStore()
const currentUser = contextStore.currentUser
const isSidebarCollapsed = ref(false)
const layout = ref()
const navItems = ref(undefined)
const route = useRoute()
const router = useRouter()
const theme = useTheme()

const footerHeight = computed(() => {
  const footer = layout.value ? layout.value.getLayoutItem('footer') : null
  return get(footer, 'size', 60)
})

onMounted(() => {
  setPreferredColorScheme()
  setPreferredSidebarState()
  if (currentUser.isAdmin) {
    navItems.value = [
      {id: 'status', title: 'Status', icon: mdiListStatus, path: '/status'},
      {id: 'publish', title: 'Publish', icon: mdiAlertCircle, path: '/publish'},
      {id: 'departments', title: 'Departments', icon: mdiAccountGroup, path: '/departments'},
      {id: 'settings', title: 'Settings', icon: mdiPlaylistEdit, path: '/lists'}
    ]
  } else if (size(currentUser.departments)) {
    navItems.value = map(currentUser.departments, department => {
      const firstInitial = department.name.charAt(0).toLowerCase()
      return {
        title: department.name,
        icon: `mdi-alpha-${firstInitial}-circle`,
        path: `/department/${department.id}`
      }
    })
  }
})

const logOut = () => {
  alertScreenReader('Logging out')
  getCasLogoutUrl().then(data => window.location.href = data.casLogoutUrl)
}

const setPreferredColorScheme = () => {
  let prefersDarkMode
  if (window.localStorage.getItem('prefersDarkMode')) {
    prefersDarkMode = window.localStorage.getItem('prefersDarkMode') === 'true'
  } else {
    prefersDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches
  }
  theme.global.name.value = prefersDarkMode ? 'dark' : 'light'
}

const setPreferredSidebarState = () => {
  if (window.localStorage.getItem('prefersSidebarCollapsed')) {
    isSidebarCollapsed.value = window.localStorage.getItem('prefersSidebarCollapsed') === 'true'
  }
}

const toggleColorScheme = () => {
  const getDark = !theme.global.current.value.dark
  theme.global.name.value = getDark ? 'dark' : 'light'
  window.localStorage.setItem('prefersDarkMode', `${getDark}`)
}

const toggleSidebarCollapsed = () => {
  isSidebarCollapsed.value = !isSidebarCollapsed.value
  window.localStorage.setItem('prefersSidebarCollapsed', isSidebarCollapsed.value)
}

const toRoute = path => router.push({path})
</script>

<style scoped>
.bg-selected-nav-item {
  background-color: #5886b1;
}
.nav-drawer-letter-spacing {
  letter-spacing: 0.1em;
}
.service-announcement {
  background-color: #f0ad4e;
  color: #000;
  margin: 0;
  padding: 10px 15px;
  position: sticky;
  top: 56px;
  width: 100%;
  z-index: 2;
}
pre {
  white-space: pre-line;
}
</style>
