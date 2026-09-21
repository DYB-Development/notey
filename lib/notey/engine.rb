require "noticed"
require "keystone_ui"

module Notey
  class Engine < ::Rails::Engine
    isolate_namespace Notey

    initializer "notey.filter_parameters" do |app|
      app.config.filter_parameters += [ :credential ]
    end

    initializer "notey.forget_notifiers_on_reload" do
      ActiveSupport::Reloader.before_class_unload { Notey.forget_notifiers }
    end

    config.to_prepare { Noticed::DeliveryMethod.include(Notey::RecordsAttempt) }

    config.after_initialize { |app| Notey.check! if app.config.eager_load }
  end
end
