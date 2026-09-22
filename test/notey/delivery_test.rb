# frozen_string_literal: true

require "test_helper"

module Notey
  class DeliveryTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
      Notey.channel(:test, delivery_method: "Noticed::DeliveryMethods::Test")
      Noticed::DeliveryMethods::Test.delivered = []
      Current.account_id = 7
    end

    teardown do
      Current.reset
      Notey.reset!
    end

    def preference_queries(&block)
      count = 0
      counter = lambda do |*, payload|
        count += 1 if payload[:name] == "Notey::Preference Load" && payload[:sql].to_s.include?("notey_preferences")
      end
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    def recipient_on(window)
      Member.create!(email: "person@example.com").tap do |member|
        Preference.create!(member: member, account_id: 7, notification_type: "comment",
          channels: %w[test], digest_window: window)
      end
    end

    test "reads a person's preference once for each channel it decides" do
      member = recipient_on("immediate")

      queries = preference_queries { perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) } }

      assert_equal 3, queries
    end

    test "keeps sending a type set to immediate" do
      perform_enqueued_jobs { CommentNotification.notify(recipient_on("immediate"), comment_id: 1) }

      assert_equal 1, Noticed::DeliveryMethods::Test.delivered.size
    end
  end
end
