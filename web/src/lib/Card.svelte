<script>
  import { createEventDispatcher } from 'svelte';
  import { pad, playtime, lastSeen, age } from './format.js';

  export let character;
  export let style = 'parch';
  export let busy = false;

  const dispatch = createEventDispatcher();

  // colours only appear when the character has an affiliation, so the card has
  // to look finished at both five rows and six
  $: rows = (() => {
    const years = age(character.dob);
    const out = [
      ['Trade', character.jobGrade ? `${character.job} · ${character.jobGrade}` : (character.job || 'Civilian')],
      ['Age', years !== null ? String(years) : '—'],
      ['Born', character.nationality || '—'],
      ['Time served', playtime(character.playtime)],
      ['Last seen', lastSeen(character.lastSeen)],
    ];
    if (character.gang) out.splice(1, 0, ['Colours', character.gang]);
    return out;
  })();
</script>

<div class="cd-{style}">
  {#if style === 'brass'}
    <span class="bolt tl"></span><span class="bolt tr"></span>
    <span class="bolt bl"></span><span class="bolt br"></span>
  {/if}

  <div class="cd-slot">Berth {pad(character.slot)}</div>
  <div class="cd-name">{character.name || 'Unnamed'}</div>

  <dl class="cd-meta">
    {#each rows as [key, value] (key)}
      <div class="m"><dt>{key}</dt><dd>{value}</dd></div>
    {/each}
  </dl>

  <div class="cd-acts">
    <button class="sail" type="button" disabled={busy} on:click={() => dispatch('sail')}>
      {busy ? 'Casting off…' : 'Weigh anchor'}
    </button>
    <button class="ghostb" class:onpaper={style === 'parch'} type="button"
            disabled={busy} on:click={() => dispatch('strike')}>Strike off</button>
  </div>
</div>
