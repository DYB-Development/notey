# frozen_string_literal: true

module Notey
  class Destinations
    def self.for(account_id, channel, member: nil)
      return nil if account_id.blank?

      Destination.find_by(account_id: account_id, channel: channel.to_s, member: member)
    end
  end
end
