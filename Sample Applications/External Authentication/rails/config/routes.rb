ActionController::Routing::Routes.draw do |map|

  #
  # login/logout
  #
  map.resource :user_session

  #
  # account management
  #
  map.resource :account, :controller => "users"
  map.resources :users

  #
  # rooms management
  #
  #map.resources :rooms
  map.connect 'rooms/:id', :controller => 'rooms', :action => 'show'

  #
  # default action
  #
  map.root :controller => "rooms", :action => "index"
end
