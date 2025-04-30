# frozen_string_literal: true

Rails.application.routes.draw do

  get 'welcome/index'

  resources :reportes do
    resources :comentarios
  end

  resources :articles do
    resources :comments
  end
  # root 'welcome#index'

  #----- es mi parte -- en español

  get 'bienvenido/index'

  resources :reportes do
    resources :comentarios
  end

  root 'bienvenido#index'

end
