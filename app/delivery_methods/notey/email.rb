# frozen_string_literal: true

module Notey
  class Email < Noticed::DeliveryMethod
    def self.reachable?(recipient)
      recipient.email.present?
    end

    def deliver
      NotificationMailer.with(notification: notification, recipient: recipient).notification.deliver_now
    end
  end
end
