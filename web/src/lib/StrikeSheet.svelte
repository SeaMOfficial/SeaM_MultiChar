<script>
  import { createEventDispatcher } from 'svelte';
  export let character;
  export let busy = false;
  const dispatch = createEventDispatcher();
</script>

<div class="sheet narrow" role="dialog" aria-modal="true">
  <div class="sh-eye">There is no undoing this</div>
  <div class="sh-t">Strike {character.name || 'this hand'} from the articles?</div>
  <p class="sh-c">Their coin, their trade and every hour they served go over the side with them.</p>
  <div class="sh-rule"><i></i></div>
  <div class="sh-acts">
    <button class="ghostb onpaper" type="button" disabled={busy} on:click={() => dispatch('close')}>Keep them aboard</button>
    <button class="strike" type="button" disabled={busy} on:click={() => dispatch('confirm')}>
      {busy ? 'Striking…' : 'Strike them off'}
    </button>
  </div>
</div>
