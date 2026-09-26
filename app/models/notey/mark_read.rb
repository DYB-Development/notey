# frozen_string_literal: true

module Notey
  class MarkRead
    def initialize(values:, person: nil, account: nil)
      @person = person
      @account_id = account.respond_to?(:id) ? account.id : account
      @values = values
    end

    def call
      mark(notification) if notification

      Kept.new
    end

    private

    def mark(notification)
      notification.mark_as_read!
      LiveInbox.read(notification) if Notey.live_updates
    end

    def notification
      @notification ||= Inbox.for(@person, account_id: @account_id).find_by(id: @values[:read])
    end
  end
end
