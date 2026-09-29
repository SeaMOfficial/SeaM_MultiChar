const RESOURCE = (typeof GetParentResourceName === 'function')
  ? GetParentResourceName()
  : 'SeaM_MultiChar';

export async function post(name, body) {
  try {
    const res = await fetch(`https://${RESOURCE}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
    });
    return await res.json();
  } catch (err) {
    return { ok: false, error: 'Lost contact with the server.' };
  }
}

// the url is owner-authored config, but it is still handed to the player's browser --
// anything but http(s) (javascript:, file:) has no business being opened
export function openUrl(url) {
  if (typeof url !== 'string') return false;
  let parsed;
  try { parsed = new URL(url); } catch (e) { return false; }
  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return false;
  if (typeof window.invokeNative === 'function') window.invokeNative('openUrl', parsed.href);
  return true;
}
