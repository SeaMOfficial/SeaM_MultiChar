<script>
  import { createEventDispatcher } from 'svelte';
  export let credits = [];
  const dispatch = createEventDispatcher();
</script>

<div class="sheet narrow" role="dialog" aria-modal="true">
  <div class="sh-eye">Built by</div>
  <div class="sh-t">Ship's company</div>
  <div class="sh-rule"><i></i></div>
  <ul class="creds">
    {#each credits as entry, i (i)}
      <li><span class="r">{entry.role || ''}</span><span class="nm2">{entry.name || ''}</span></li>
    {/each}
  </ul>
  <div class="sh-acts">
    <button class="ghostb onpaper" type="button" on:click={() => dispatch('close')}>Close</button>
  </div>
</div>
