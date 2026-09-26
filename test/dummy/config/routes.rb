Rails.application.routes.draw do
  mount Notey::Engine => "/notey"

  resource :inbox, only: [ :show, :update ], controller: "inbox"
end
