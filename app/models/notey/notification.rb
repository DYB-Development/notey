# frozen_string_literal: true

module Notey
  class Notification < Noticed::Event
    class_attribute :notey_notification_type, instance_writer: false

    def self.notey_type(name)
      self.notey_notification_type = name.to_s
    end

    def self.delivery_methods
      Notey.registered_channels.to_h do |channel|
        [ channel.name.to_sym, Noticed::Deliverable::DeliverBy.new(channel.name.to_sym, delivery_config(channel)) ]
      end
    end

    def self.delivery_config(channel)
      config = ActiveSupport::OrderedOptions.new
      config[:class] = channel.delivery_method if channel.delivery_method
      config
    end
  end
end
