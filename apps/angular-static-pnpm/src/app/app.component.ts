import { NgFor } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { getBaseValue, saveValue } from './store/store';

@Component({
  selector: 'app-root',
  template: `
    <div id="app">
      <input
        type="text"
        [(ngModel)]="newTodo"
        placeholder="Add a new element"
      />
      <button
        type="button"
        [disabled]="newTodo.length === 0"
        (click)="addTodo()"
      >
        Add
      </button>

      <ul>
        <li *ngFor="let todo of todos">
          {{ todo.text }}
          <button (click)="removeTodo(todo)">x</button>
        </li>
      </ul>
    </div>
  `,
  imports: [FormsModule, NgFor],
  standalone: true,
})
export class AppComponent {
  newTodo = '';
  todos: { text: string }[] = [];

  ngOnInit() {
    this.todos = getBaseValue();
  }

  addTodo() {
    this.todos.push({
      text: this.newTodo,
    });
    this.newTodo = '';

    saveValue(this.todos);
  }

  removeTodo(todo: { text: string }) {
    this.todos.splice(this.todos.indexOf(todo), 1);

    saveValue(this.todos);
  }
}
