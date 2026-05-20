import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import './App.css';

function App() {
  const [todos, setTodos] = useState([]);
  const [newTask, setNewTask] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [updatedTask, setUpdatedTask] = useState('');

  const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api/todos';

  const fetchTodos = async () => {
    const res = await axios.get(API_URL);
    setTodos(res.data);
  };

  useEffect(() => {
    fetchTodos();
  }, []);

  const addTodo = async () => {
    if (!newTask) return;
    await axios.post(API_URL, { title: newTask });
    setNewTask('');
    fetchTodos();
  };

  const deleteTodo = async (id) => {
    await axios.delete(`${API_URL}/${id}`);
    fetchTodos();
  };

  const toggleComplete = async (todo) => {
    await axios.put(`${API_URL}/${todo.id}`, {
      title: todo.title,
      completed: !todo.completed
    });
    fetchTodos();
  };

  const updateTodo = async (id) => {
    await axios.put(`${API_URL}/${id}`, { title: updatedTask, completed: false });
    setEditingId(null);
    setUpdatedTask('');
    fetchTodos();
  };

  return (
    <div className="app-container">
      <h1>To-Do List</h1>

      <div className="input-container">
        <input
          type="text"
          value={newTask}
          placeholder="Add a new task..."
          onChange={(e) => setNewTask(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && addTodo()}
        />
        <button onClick={addTodo}>Add</button>
      </div>

      <ul className="todo-list">
        <AnimatePresence>
          {todos.map((todo) => (
            <motion.li
              key={todo.id}
              initial={{ opacity: 0, x: -50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 50 }}
              layout
              className={`todo-item ${todo.completed ? 'completed' : ''}`}
            >
              {editingId === todo.id ? (
                <>
                  <input
                    type="text"
                    value={updatedTask}
                    onChange={(e) => setUpdatedTask(e.target.value)}
                  />
                  <button className="save-btn" onClick={() => updateTodo(todo.id)}>Save</button>
                </>
              ) : (
                <>
                  <span
                    onClick={() => toggleComplete(todo)}
                    className="todo-title"
                  >
                    {todo.completed ? '✅ ' : ''}{todo.title}
                  </span>
                  <div className="actions">
                    <button onClick={() => { setEditingId(todo.id); setUpdatedTask(todo.title); }}>Edit</button>
                    <button className="delete-btn" onClick={() => deleteTodo(todo.id)}>Delete</button>
                  </div>
                </>
              )}
            </motion.li>
          ))}
        </AnimatePresence>
      </ul>
    </div>
  );
}

export default App;
