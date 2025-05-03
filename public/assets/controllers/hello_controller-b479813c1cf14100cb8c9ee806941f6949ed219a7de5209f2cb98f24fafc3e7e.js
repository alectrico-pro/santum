import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
 static targets = [ "name", "output", "field" ]

  connect() {
    // this.element.textContent = "Hello World!"
    console.log('Hello World hello_controller.js');
  }

  greet() {
    console.log('greet');
    this.outputTarget.textContent =
      `Hola, ${this.nameTarget.value}!. ¿Qué problemas tenemos para hoy?  `
    this.fieldTarget.textContent =
      `Hola, ${this.nameTarget.value}`	  
  }
};
