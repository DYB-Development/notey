# frozen_string_literal: true

module Notey
  class Destinations
    def self.for(account_id, channel, member: nil)
      return nil if account_id.blank?

      of_member(account_id, channel, member) || of_account(account_id, channel)
    end

    def self.of_member(account_id, channel, member)
      return nil if member.nil?

      Destination.find_by(account_id: account_id, channel: channel.to_s, member: member)
    end

    def self.of_account(account_id, channel)
      Destination.where(account_id: account_id, channel: channel.to_s, member_id: nil).first
    end
    private_class_method :of_member, :of_account
  end
end
