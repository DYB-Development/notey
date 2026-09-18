Notey::Engine.routes.draw do
  resource :preferences, only: [ :show, :update ]
end
