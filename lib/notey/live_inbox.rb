# frozen_string_literal: true

module Notey
  class LiveInbox
    def self.stream(person, account_id)
      [ person, :notey_inbox, account_id ]
    end

    def self.deliver(notification)
      return if notification.account_id.blank?

      Turbo::StreamsChannel.broadcast_prepend_to(
        *stream(notification.recipient, notification.account_id),
        target: "notey_inbox",
        html: row(notification)
      )
    end

    def self.row(notification)
      Notey::ApplicationController.render(
        partial: "notey/notification", locals: { notification: notification, submit_url: Notey.mark_read_url.call(notification) }
      )
    end
  end
end
