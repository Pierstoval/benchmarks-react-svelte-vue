import { createEffect, createRoot, createSignal } from 'solid-js';

type Todo = { text: string };

const storageKey = 'todoStore';

function getBaseValue(): Todo[] {
  let value = '[]';
  if (typeof window !== 'undefined') {
    value = window?.localStorage?.getItem(storageKey) || '[]';
  }
  return JSON.parse(value);
}

function saveValue(values: Todo[]) {
  if (typeof window === 'undefined') {
    console.warn('Window variable is undefined, cannot save values.');
    return;
  }

  window.localStorage.setItem(storageKey, JSON.stringify(values || []));
}

function createTodoStore() {
  const [todos, setTodos] = createSignal(getBaseValue());

  createEffect(() => {
    saveValue(todos());
  });

  return { todos, setTodos };
}

export default createRoot(createTodoStore);
