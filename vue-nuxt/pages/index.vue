<script lang="ts">
    import {todoStore} from '~/lib/todoStore';

    export default {
      data() {
        return {
          todoStore,
          newTodo: '',
        };
      },
      methods: {
        addTodo() {
          if (!this.newTodo) {
            return;
          }
          todoStore.update((todos: Array<{ text: string }>) => [...todos, {text: this.newTodo}])
          this.newTodo = '';
          this.$refs.input.focus();
        },
        removeTodo(todo: { text: string }) {
          todoStore.update((todos: Array<{ text: string }>) => todos.filter(i => i !== todo));
        },
      },
    };
</script>

<template>
  <div>
    <input type="text" ref="input" placeholder="Add a new element" v-model.trim="newTodo" />
    <button type="button" :disabled="this.newTodo.length === 0" @click="addTodo">Add</button>
    <ul>
      <li v-for="todo in todoStore.values">
        {{ todo.text }}
        <button @click="() => removeTodo(todo)">x</button>
      </li>
    </ul>
  </div>
</template>
