<script lang="ts">
    import {todoStore} from './lib/todoStore';

    let input: HTMLElement;
    let newTodo: string = '';

    function addTodo() {
        if (!newTodo) {
            return;
        }
        todoStore.update((todos) => [...todos, {text: newTodo}])
        newTodo = '';
        input.focus();
    }

    function removeTodo(todo) {
        todoStore.update((todos) => todos.filter(i => i !== todo));
    }
</script>

<input bind:this={input} type="text" bind:value={newTodo} placeholder="Add a new element"/>
<button type="button" disabled={newTodo.length === 0} on:click={addTodo}>Add</button>

<ul>
    {#each $todoStore as todo}
        <li>
            {todo.text}
            <button on:click={() => removeTodo(todo)}>x</button>
        </li>
    {/each}
</ul>
