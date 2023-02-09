import { reactive } from 'vue'

const storageKey = 'todoStore';

function getBaseValues() {
    let value = '[]';
    if (typeof window !== 'undefined') {
        value = window?.localStorage?.getItem(storageKey) || '[]';
    }
    return JSON.parse(value);
}

function saveValue(values: Array<{ text: string }>) {
    if (typeof window === 'undefined') {
        console.warn('Window variable is undefined, cannot save values.');
        return;
    }

    window.localStorage.setItem(storageKey, JSON.stringify(values || []));
}

export const todoStore = reactive({
    values: getBaseValues(),
    update: function(callback: Function) {
        todoStore.values = callback(todoStore.values);
        saveValue(todoStore.values);
    }
});
