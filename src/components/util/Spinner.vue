<template>
  <v-progress-circular
    class="spinner"
    color="tertiary"
    :indeterminate="true"
    rotate="5"
    size="64"
    width="8"
  />
</template>

<style scoped>
  .spinner {
    position: fixed;
    top: 0;
    right: 0;
    bottom: 0;
    left: 0;
    height: 2em;
    margin: auto;
    overflow: show;
    width: 2em;
    z-index: 999;
  }
</style>
