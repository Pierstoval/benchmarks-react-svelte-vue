import React from "react";

const storageKey = 'todoStore';

export function getBaseValue() {
  let value = '[]';
  if (typeof window !== 'undefined') {
    value = window?.localStorage?.getItem(storageKey) || '[]';
  }
  return JSON.parse(value);
}

export function saveValue(values) {
  if (typeof window === 'undefined') {
    console.warn('Window variable is undefined, cannot save values.');
    return;
  }

  window.localStorage.setItem(storageKey, JSON.stringify(values || []));
}

export const TodoContext = React.createContext(getBaseValue);
