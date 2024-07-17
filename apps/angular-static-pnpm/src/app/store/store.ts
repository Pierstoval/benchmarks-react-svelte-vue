const storageKey = 'todoStore';

export function saveValue(values: Array<{ text: string }>) {
  if (typeof window === 'undefined') {
    console.warn('Window variable is undefined, cannot save values.');
    return;
  }

  window.localStorage.setItem(storageKey, JSON.stringify(values || []));
}

export function getBaseValue(): Array<{ text: string }> {
  let value = '[]';
  if (typeof window !== 'undefined') {
    value = window?.localStorage?.getItem(storageKey) || '[]';
  }
  return JSON.parse(value);
}
