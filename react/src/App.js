import React, { useEffect, useState } from "react";
import { getBaseValue, saveValue, TodoContext } from "./store/TodoContext";
import './App.css';

function App() {
  const [newTodo, setNewTodo] = useState('');
  const [todos, setTodos] = useState(getBaseValue);

  useEffect(() => {
    saveValue(todos);
  }, [todos]);

  function addTodo () {
    setTodos([...todos, {text: newTodo}]);
    setNewTodo('');
  }

  function removeTodo (todo) {
    setTodos(todos.filter(t => t !== todo));
  }

  return (
      <div id="app">
          <TodoContext.Provider value={[todos, setTodos]}>
              <input type="text" value={newTodo} onChange={({target}) => setNewTodo(target.value)} placeholder="Add a new element"/>
              <button type="button" disabled={newTodo.length === 0} onClick={addTodo}>Add</button>

              <ul>
                  {todos.map((todo, index) => (
                      <li key={index}>
                          {todo.text}
                          <button onClick={() => removeTodo(todo)}>x</button>
                      </li>
                  ))}
              </ul>
          </TodoContext.Provider>
      </div>
  );
}

export default App;
