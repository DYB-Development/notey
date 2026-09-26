# frozen_string_literal: true

module Notey
  class LiveInbox
    def self.stream(person, account_id)
      [ person, :notey_inbox, account_id ]
    end
  end
end
