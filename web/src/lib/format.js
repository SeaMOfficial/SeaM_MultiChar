export const pad = (n) => String(n).padStart(2, '0');

export function playtime(seconds) {
  if (!seconds) return 'Never sailed';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  return h >= 1 ? `${h}h ${m}m` : `${m}m`;
}

export function lastSeen(value) {
  if (!value) return '—';
  const then = new Date(String(value).replace(' ', 'T'));
  if (isNaN(then)) return '—';
  const days = Math.floor((Date.now() - then.getTime()) / 86400000);
  if (days <= 0) return 'Today';
  if (days === 1) return 'Yesterday';
  if (days < 30) return `${days} days ago`;
  return then.toLocaleDateString();
}

export function age(dob) {
  if (!dob) return null;
  const born = new Date(dob);
  if (isNaN(born)) return null;
  const now = new Date();
  let years = now.getFullYear() - born.getFullYear();
  const m = now.getMonth() - born.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < born.getDate())) years--;
  return years;
}

export const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'];

// days in the picked month, so 31 February can't be chosen at all
export function daysIn(month, year) {
  return new Date(year, month, 0).getDate();
}
