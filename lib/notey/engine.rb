require "noticed"
require "keystone_ui"

module Notey
  class Engine < ::Rails::Engine
    isolate_namespace Notey
  end
end
