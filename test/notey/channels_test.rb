# frozen_string_literal: true

require "test_helper"

module Notey
  class ChannelsTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

    test "answers the channels a person stored for a type in an account" do
      Notey.channel(:sms)
      member = Member.create!
      Preference.create!(member: member, account_id: 7, notification_type: "comment", channels: %w[sms])

      assert_equal %w[sms], Channels.for(member, "comment", account_id: 7)
    end
  end
end
