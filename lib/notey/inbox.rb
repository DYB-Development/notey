# frozen_string_literal: true

module Notey
  class Inbox
    def self.for(member, account_id:)
      return Noticed::Notification.none if account_id.blank?

      Noticed::Notification.where(recipient: member, account_id: account_id)
    end
  end
end
