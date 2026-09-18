# frozen_string_literal: true

module Notey
  class Inbox
    def self.for(member, account_id:)
      Noticed::Notification.where(recipient: member, account_id: account_id)
    end
  end
end
