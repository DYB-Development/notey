require "noticed"
require "keystone_ui"

module Notey
  class Engine < ::Rails::Engine
    isolate_namespace Notey

    config.after_initialize { |app| Notey.check! if app.config.eager_load }
  end
end
