require "noticed"
require "keystone_ui"

module Notey
  class Engine < ::Rails::Engine
    isolate_namespace Notey

    initializer "notey.filter_parameters" do |app|
      app.config.filter_parameters += [ :credential ]
    end

    config.after_initialize { |app| Notey.check! if app.config.eager_load }
  end
end
