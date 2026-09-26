# frozen_string_literal: true

module Notey
  class LiveInbox
    def self.stream(person, account_id)
      [ person, :notey_inbox, account_id ]
    end

    def self.deliver(notification)
      return if notification.account_id.blank?

      Turbo::StreamsChannel.broadcast_prepend_to(
        *stream_of(notification), target: "notey_inbox", html: row(notification)
      )
      push_unread_count(notification)
    end

    def self.read(notification)
      Turbo::StreamsChannel.broadcast_replace_to(
        *stream_of(notification), target: "notey_notification_#{notification.id}", html: row(notification)
      )
      push_unread_count(notification)
    end

    def self.push_unread_count(notification)
      Turbo::StreamsChannel.broadcast_replace_to(
        *stream_of(notification), target: "notey_unread_count", html: unread_count(notification)
      )
    end

    def self.stream_of(notification)
      stream(notification.recipient, notification.account_id)
    end

    def self.row(notification)
      Notey::ApplicationController.render(
        partial: "notey/notification",
        locals: { notification: notification, submit_url: Notey.mark_read_url.call(notification) }
      )
    end

    def self.unread_count(notification)
      Notey::ApplicationController.render(
        partial: "notey/unread_count",
        locals: { person: notification.recipient, account: notification.account_id }
      )
    end
  end
end
