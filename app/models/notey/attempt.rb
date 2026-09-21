# frozen_string_literal: true

module Notey
  class Attempt < ApplicationRecord
    belongs_to :notification, class_name: "Noticed::Notification"

    def send_again
      delivery = notification.event.class.delivery_methods.fetch(channel.to_sym)

      destroy
      delivery.perform_later(notification)
    end
  end
end
