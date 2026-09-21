# frozen_string_literal: true

module Notey
  class Notification < Noticed::Event
    class_attribute :notey_notification_type, instance_writer: false

    def self.notey_type(name)
      self.notey_notification_type = name.to_s
    end
  end
end
