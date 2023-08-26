import type { Component } from 'solid-js';
import { createSignal, For } from 'solid-js';
import todoStore from './lib/todoStore';
import './App.css';

type Todo = { text: string };

const App: Component = () => {
  let input: HTMLInputElement | undefined;
  const [newTodo, setNewTodo] = createSignal('');
  const { todos, setTodos } = todoStore;

  function addTodo() {
    if (!newTodo()) {
      return;
    }
    setTodos([...todos(), {text: newTodo()}]);
    setNewTodo('');
    input?.focus();
  }

  function removeTodo(todo: Todo) {
    setTodos(todos().filter(t => t !== todo));
  }

  return (
    <div id="app">
      <input ref={input} type="text" value={newTodo()} onInput={({target}) => setNewTodo(target.value)} placeholder="Add a new element"/>
      <button type="button" disabled={newTodo().length === 0} onClick={addTodo}>Add</button>

      <ul>
        <For each={todos()}>
          {(todo) => (
            <li>
                {todo.text}
                <button onClick={() => removeTodo(todo)}>x</button>
            </li>
          )}
        </For>
      </ul>
    </div>
  );
};

export default App;
