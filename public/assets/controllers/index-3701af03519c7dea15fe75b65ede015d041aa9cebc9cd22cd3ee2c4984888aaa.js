// Import and register all your controllers from the importmap under controllers/*

import { Application } from "controllers/application"

//https://www.youtube.com/watch?v=ZD7r75O46zM
//PAra Registrar más abajo el controlador Caroussel en mi application
//import Caroussel from '@estimulus-components/carousel' 

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)
//
// 
////https://www.youtube.com/watch?v=ZD7r75O46zM
const application = Application.start()

//https://www.youtube.com/watch?v=ZD7r75O46zM
////Registrando el controlador Caroussel en mi application
application.register('caroussel', Caroussel );
