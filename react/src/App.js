import React, { useEffect, useState } from "react";
import { getBaseValue, saveValue, TodoContext } from "./store/TodoContext";
import './App.css';

function App() {
  const [newTodo, setNewTodo] = useState('');
  const [todos, setTodos] = useState(getBaseValue);

  useEffect(() => {
    saveValue(todos);
  }, [todos]);

  const add = () => {
    setTodos([newTodo, ...todos]);
    setNewTodo('');
  }

  const remove = (todo) => {
    setTodos(todos.filter(t => t !== todo));
  }

  return (
    <TodoContext.Provider value={[todos, setTodos]}>
      <input type="text" value={newTodo} onChange={({target}) => setNewTodo(target.value)} placeholder="Add a new element"/>
      <button type="button" disabled={newTodo.length === 0} onClick={add}>Add</button>

      <ul>
        {todos.map((todo, index) => (
          <div key={index} className="todo__item">
            <p>{todo}</p>
            <button onClick={() => remove(todo)}>X</button>
          </div>
        ))}
      </ul>
    </TodoContext.Provider>
  );
}

export default App;
