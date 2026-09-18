Notey::Engine.routes.draw do
  resource :preferences, only: [ :show, :update ]
  resources :notifications, only: [ :index, :update ]
end
