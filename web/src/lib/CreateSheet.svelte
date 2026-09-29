<script>
  import { createEventDispatcher } from 'svelte';
  import { pad, age, MONTHS, daysIn } from './format.js';

  // not named `slot` -- svelte treats that attribute as a slot name, not a prop
  export let berth = 1;
  export let busy = false;
  export let nationalities = ['American'];
  export let minAge = 18;
  export let maxAge = 90;

  const dispatch = createEventDispatcher();

  let first = '';
  let last = '';
  let d = 15, m = 6, y = new Date().getFullYear() - 26;
  let gender = 0;
  let nat = nationalities[0] || 'American';
  let error = null;

  const NAME_RX = /^[A-Za-z][A-Za-z '-]{1,23}$/;
  const yearNow = new Date().getFullYear();

  // the year list is the legal range, so an out-of-range birthday can't be picked
  $: years = Array.from({ length: maxAge - minAge + 1 }, (_, i) => yearNow - minAge - i);
  $: months = MONTHS.map((n, i) => ({ v: i + 1, n }));
  $: days = Array.from({ length: daysIn(m, y) }, (_, i) => i + 1);
  // a shorter month must not leave the 31st selected
  $: if (d > daysIn(m, y)) d = daysIn(m, y);

  $: dob = `${y}-${pad(m)}-${pad(d)}`;

  function submit() {
    if (busy) return;
    const years2 = age(dob);
    error = !NAME_RX.test(first.trim()) ? 'A given name needs two letters or more.'
      : !NAME_RX.test(last.trim()) ? 'A family name needs two letters or more.'
      : years2 === null ? 'That date is not a real one.'
      : years2 < minAge ? `Hands must be at least ${minAge}.`
      : years2 > maxAge ? `Hands must be under ${maxAge}.`
      : null;
    if (error) return;

    dispatch('sign', {
      slot: berth,
      firstname: first.trim(),
      lastname: last.trim(),
      dob,
      gender,
      nationality: nat,
    });
  }
</script>

<div class="sheet" role="dialog" aria-modal="true">
  <div class="sh-eye">Berth {pad(berth)}</div>
  <div class="sh-t">Sign the articles</div>
  <p class="sh-c">Every hand aboard puts their name down. Yours goes here.</p>
  <div class="sh-rule"><i></i></div>

  <div class="frow2">
    <label class="fld"><span>Given name</span>
      <input type="text" maxlength="24" autocomplete="off" spellcheck="false"
             bind:value={first} on:keydown={(e) => e.key === 'Enter' && submit()}>
    </label>
    <label class="fld"><span>Family name</span>
      <input type="text" maxlength="24" autocomplete="off" spellcheck="false"
             bind:value={last} on:keydown={(e) => e.key === 'Enter' && submit()}>
    </label>
  </div>

  <div class="frow2">
    <div class="fld"><span>Born</span>
      <div class="dob">
        <span class="dw d-d"><select bind:value={d}>{#each days as v}<option value={v}>{v}</option>{/each}</select></span>
        <span class="dw d-m"><select bind:value={m}>{#each months as o}<option value={o.v}>{o.n}</option>{/each}</select></span>
        <span class="dw d-y"><select bind:value={y}>{#each years as v}<option value={v}>{v}</option>{/each}</select></span>
      </div>
    </div>
    <label class="fld sel"><span>Sailing from</span>
      <select bind:value={nat}>{#each nationalities as n}<option value={n}>{n}</option>{/each}</select>
    </label>
  </div>

  <div class="frow2"><div class="fld"><span>Build</span>
    <div class="seg">
      <button type="button" class:on={gender === 0} on:click={() => gender = 0}>Male</button>
      <button type="button" class:on={gender === 1} on:click={() => gender = 1}>Female</button>
    </div>
  </div></div>

  {#if error}<p class="ferr">{error}</p>{/if}

  <div class="sh-acts">
    <button class="ghostb onpaper" type="button" disabled={busy} on:click={() => dispatch('close')}>Not yet</button>
    <button class="sail" type="button" disabled={busy} on:click={submit}>
      {busy ? 'Signing…' : 'Put down the name'}
    </button>
  </div>
</div>
