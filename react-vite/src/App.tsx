import React, { useEffect, useState } from 'react'
import { getBaseValue, saveValue, type Todo, TodoContext } from "./store/TodoContext";
import './App.css'

function App() {
  const [newTodo, setNewTodo] = useState('');
  const [todos, setTodos] = useState<Todo[]>(getBaseValue);

  useEffect(() => {
    saveValue(todos);
  }, [todos]);

  const add = () => {
    setTodos([{text: newTodo}, ...todos]);
    setNewTodo('');
  }

  const remove = (todo: Todo) => {
    setTodos(todos.filter((t: Todo) => t !== todo));
  }

  return (
    <TodoContext.Provider value={[todos, setTodos] as any}>
      <div className="App">
        <input type="text" value={newTodo} onChange={({target}) => setNewTodo(target.value)} placeholder="Add a new element"/>
        <button type="button" disabled={newTodo.length === 0} onClick={add}>Add</button>

        <ul>
          {todos.map((todo, index) => (
            <div key={index} className="todo__item">
              <p>{todo.text}</p>
              <button onClick={() => remove(todo)}>X</button>
            </div>
          ))}
        </ul>
      </div>
    </TodoContext.Provider>
  )
}

export default App
