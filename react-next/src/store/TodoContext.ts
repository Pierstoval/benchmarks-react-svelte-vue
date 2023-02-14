import React from "react";

const storageKey = 'todos';

export function getBaseValue(): string[] {
  let value = '[]';
  if (typeof window !== 'undefined') {
    value = window.localStorage.getItem(storageKey) || '[]';
  }
  return JSON.parse(value);
}

export function saveValue(values: string[]) {
  if (typeof window === 'undefined') {
    console.warn('Window variable is undefined, cannot save values.');
    return;
  }

  window.localStorage.setItem(storageKey, JSON.stringify(values || []));
}

export const TodoContext = React.createContext(getBaseValue);
