# frozen_string_literal: true

Rails.application.routes.draw do

  #get 'welcome/index'

 # resources :articles do
 #   resources :comments
 # end
  # root 'welcome#index'

  #----- es mi parte -- en español

  get 'bienvenido/index'

  resources :reportes do
    resources :comentarios
  end

  #oot 'bienvenido#index'
  root 'reportes#new'


  #Este es el webhook de la app whappy en facebook
  get  'api/v1/electrico/presupuestos/webhook'
  post 'api/v1/electrico/presupuestos/webhook'


end
