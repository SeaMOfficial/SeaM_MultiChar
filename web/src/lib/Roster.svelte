<script>
  import { createEventDispatcher } from 'svelte';
  import { pad, playtime } from './format.js';

  export let characters = [];
  export let maxSlots = 1;
  export let selected = null;
  export let style = 'articles';

  const dispatch = createEventDispatcher();
  const HEADED = { articles: 'The Ship’s Articles', logbook: 'Crew Log' };

  // one row per berth, occupied or not -- a gap in the list is information
  $: berths = Array.from({ length: maxSlots }, (_, i) => {
    const slot = i + 1;
    return { slot, character: characters.find((c) => c.slot === slot) || null };
  });
</script>

<div class="rs rs-{style}">
  {#if HEADED[style]}<div class="ah">{HEADED[style]}</div>{/if}

  {#each berths as { slot, character } (slot)}
    <button
      class="berth"
      class:vacant={!character}
      class:on={character && character.citizenid === selected}
      type="button"
      on:click={() => character
        ? dispatch('pick', character.citizenid)
        : dispatch('enlist', slot)}
    >
      {#if style === 'plates'}
        <span class="bolt tl"></span><span class="bolt tr"></span>
        <span class="bolt bl"></span><span class="bolt br"></span>
      {/if}
      <span class="seal">{pad(slot)}</span>
      <span class="bx">
        {#if character}
          <span class="bn">{character.name || 'Unnamed'}</span>
          <span class="bs">{character.job || 'Civilian'} · {playtime(character.playtime)}</span>
        {:else}
          <span class="bn">Berth unsigned</span>
        {/if}
      </span>
    </button>
  {/each}
</div>
