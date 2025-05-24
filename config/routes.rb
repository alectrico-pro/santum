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
    member do
      get :avisar
    end
    resources :comentarios
  end

  #root 'bienvenido#index'
  root 'reportes#index'

  #root 'reportes#new'


  #Este es el webhook de la app whappy en facebook
  get  'api/v1/santum/webhook'
  post 'api/v1/santum/webhook'

end
