# frozen_string_literal: true

require "test_helper"

module Notey
  class NotificationsTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    teardown do
      Current.reset
      Notey.reset!
    end

    def headers_for(member, account_id: 7)
      { "X-Member-Id" => member.id.to_s, "X-Account-Id" => account_id.to_s }
    end

    def notify(member, account_id: 7)
      Notey.catalog { notification :comment, channels: %w[test], default: %w[test] }
      Current.account_id = account_id
      perform_enqueued_jobs { CommentNotifier.deliver(member) }
      Current.reset
    end

    test "lists the notifications addressed to a person in the account they are in" do
      member = Member.create!
      notify(member)

      get "/notey/notifications", headers: headers_for(member)

      assert_select "[data-notification-id]", 1
    end
  end
end
