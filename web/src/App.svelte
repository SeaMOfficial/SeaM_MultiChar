<script>
  import { onMount } from 'svelte';
  import Roster from './lib/Roster.svelte';
  import Card from './lib/Card.svelte';
  import CreateSheet from './lib/CreateSheet.svelte';
  import StrikeSheet from './lib/StrikeSheet.svelte';
  import CompanySheet from './lib/CompanySheet.svelte';
  import { post, openUrl } from './lib/nui.js';

  let open = false;
  let characters = [];
  let maxSlots = 1;
  let selected = null;
  let config = {};
  let busy = false;
  let sheet = null;          // create | strike | company
  let createSlot = 1;
  let striking = null;
  let toast = null;          // { text, bad }
  let toastTimer = null;

  // an owner typo in config must not blank the screen, so anything unknown falls back
  const STYLES = {
    roster: new Set(['articles', 'plates', 'manifest', 'logbook']),
    card: new Set(['parch', 'brass', 'plain']),
  };

  $: current = characters.find((c) => c.citizenid === selected) || null;
  $: usedSlots = new Set(characters.map((c) => c.slot));
  $: firstFree = (() => {
    for (let i = 1; i <= maxSlots; i++) if (!usedSlots.has(i)) return i;
    return null;
  })();
  $: rosterStyle = STYLES.roster.has(config.roster) ? config.roster : 'articles';
  $: cardStyle = STYLES.card.has(config.card) ? config.card : 'parch';

  function say(text, bad) {
    toast = { text, bad: !!bad };
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { toast = null; }, 4000);
  }

  // Config.UI.accent drives the one interactive colour; ignore anything that is not a hex
  function applyAccent(hex) {
    if (typeof hex !== 'string' || !/^#[0-9a-f]{6}$/i.test(hex)) return;
    const n = parseInt(hex.slice(1), 16);
    const root = document.documentElement;
    root.style.setProperty('--signal', hex);
    root.style.setProperty('--signal-rgb', `${(n >> 16) & 255},${(n >> 8) & 255},${n & 255}`);
  }

  function closeSheet() {
    sheet = null;
    striking = null;
  }

  async function pick(citizenid) {
    if (busy || citizenid === selected) return;
    selected = citizenid;
    await post('preview', { citizenid });
  }

  async function sail() {
    if (busy || !selected) return;
    busy = true;
    const res = await post('play', { citizenid: selected });
    busy = false;
    if (!res.ok) say(res.error || 'Could not load that character.', true);
  }

  function enlist(slot) {
    if (busy) return;
    const target = slot || firstFree;
    if (target === null) return say('Every berth is taken.', true);
    createSlot = target;
    sheet = 'create';
  }

  async function sign(payload) {
    if (busy) return;
    busy = true;
    const res = await post('create', payload);
    busy = false;
    if (!res.ok) return say(res.error || 'Could not sign that hand on.', true);
    closeSheet();
  }

  async function strikeOff() {
    if (busy || !striking) return;
    busy = true;
    const res = await post('delete', { citizenid: striking });
    busy = false;
    closeSheet();
    if (!res.ok) say(res.error || 'Could not strike that hand off.', true);
  }

  function onMessage(event) {
    const data = event.data || {};

    if (data.action === 'open' || data.action === 'update') {
      if (data.config) { config = data.config; applyAccent(config.accent); }
      characters = Array.isArray(data.characters) ? data.characters : [];
      maxSlots = Number(data.maxSlots) || 1;
      selected = data.selected || null;
      if (data.action === 'open') { open = true; closeSheet(); }
      return;
    }

    if (data.action === 'close') {
      open = false;
      closeSheet();
      toast = null;
      clearTimeout(toastTimer);
    }
  }

  function onKey(event) {
    if (event.key === 'Escape' && sheet) closeSheet();
  }

  onMount(() => {
    window.addEventListener('message', onMessage);
    window.addEventListener('keydown', onKey);
    return () => {
      window.removeEventListener('message', onMessage);
      window.removeEventListener('keydown', onKey);
      clearTimeout(toastTimer);
    };
  });
</script>

<!-- kept mounted rather than {#if}, so opening the screen is not a full rebuild -->
<div class="cs" hidden={!open}>
  <div class="scrim"></div>

  <aside class="rail">
    <header class="rail-head">
      <div class="eyebrow">{config.serverName || 'SeaM'}</div>
      <h1 class="rail-title">Who sails tonight?</h1>
      {#if config.tagline}<p class="tagline">{config.tagline}</p>{/if}
      <div class="rule"><i></i></div>
    </header>

    <div class="rail-body">
      <Roster
        {characters} {maxSlots} {selected} style={rosterStyle}
        on:pick={(e) => pick(e.detail)}
        on:enlist={(e) => enlist(e.detail)} />

      {#if firstFree !== null}
        <button class="enlist" type="button" on:click={() => enlist(null)}>
          <span class="q">+</span> Sign the articles
        </button>
      {/if}
    </div>

    <footer class="rail-foot">
      <div class="foot-links">
        {#if (config.credits || []).length}
          <button class="flink" type="button" on:click={() => sheet = 'company'}>Ship's company</button>
        {/if}
        {#if config.store && config.store.url}
          <button class="flink" type="button" on:click={() => openUrl(config.store.url)}>
            {config.store.label || 'Ship\'s store'}
          </button>
        {/if}
      </div>
    </footer>
  </aside>

  {#if characters.length === 0}
    <div class="firstlight">
      <div class="fl-t">No hands aboard</div>
      <p class="fl-c">Nobody has signed on under your name yet. Put one down on the articles and you can be at the shoreline inside a minute.</p>
      <div class="fl-a"><button class="sail" type="button" on:click={() => enlist(null)}>Sign the articles</button></div>
    </div>
  {:else if current}
    <div class="card">
      <Card character={current} style={cardStyle} {busy}
            on:sail={sail}
            on:strike={() => { striking = selected; sheet = 'strike'; }} />
    </div>
  {/if}

  {#if toast}
    <div class="toastw" class:bad={toast.bad}>{toast.text}</div>
  {/if}

  {#if sheet}
    <!-- only a click on the dark itself closes; nothing inside has to stop the bubble -->
    <div class="sheetwrap" role="presentation"
         on:click={(e) => { if (e.target === e.currentTarget) closeSheet(); }}>
      {#if sheet === 'create'}
        <CreateSheet
          berth={createSlot} {busy}
          nationalities={config.nationalities || ['American']}
          minAge={config.minAge || 18}
          maxAge={config.maxAge || 90}
          on:sign={(e) => sign(e.detail)}
          on:close={closeSheet} />
      {:else if sheet === 'strike' && current}
        <StrikeSheet character={current} {busy}
          on:confirm={strikeOff}
          on:close={closeSheet} />
      {:else if sheet === 'company'}
        <CompanySheet credits={config.credits || []} on:close={closeSheet} />
      {/if}
    </div>
  {/if}
</div>
