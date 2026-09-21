# frozen_string_literal: true

module Notey
  class Attempt < ApplicationRecord
    belongs_to :notification, class_name: "Noticed::Notification"

    def send_again
      raise UnsendableAttempt, "#{channel} was already sent for this notification" if state == "sent"

      delivery = notification.event.class.delivery_methods.fetch(channel.to_sym)

      destroy
      delivery.perform_later(notification)
    end
  end
end
