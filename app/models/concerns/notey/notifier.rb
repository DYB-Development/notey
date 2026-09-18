# frozen_string_literal: true

module Notey
  module Notifier
    extend ActiveSupport::Concern

    included do
      class_attribute :notey_notification_type, instance_writer: false

      Notey.register_notifier(self)
    end

    class_methods do
      def notey_type(name)
        self.notey_notification_type = name.to_s
      end
    end
  end
end
