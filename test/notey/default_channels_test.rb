# frozen_string_literal: true

require "test_helper"

module Notey
  class DefaultChannelsTest < ActiveSupport::TestCase
    teardown { Notey.reset! }

    test "gives a person in-app and email before they choose" do
      Notey.forget_notifiers
      Notey.register_notifier(notifier_delivering(:comment, :email, :in_app, :sms))

      found = Channels.for(Member.create!, "comment", account_id: 7)

      assert_equal %w[email in_app], found.sort
    end
  end
end
