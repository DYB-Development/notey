# frozen_string_literal: true

require "test_helper"

module Notey
  class DigestRunTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper
    include ActiveRecord::Assertions::QueryAssertions

    teardown do
      Current.reset
      Notey.reset!
    end

    def member_with_daily_comment
      member = Member.create!(email: "person@example.com")
      Preference.create!(member: member, account_id: 7, notification_type: "comment",
        channels: %w[email], digest_window: "daily")
      member
    end

    def notify(member, count)
      Current.account_id = 7
      count.times { perform_enqueued_jobs { CommentNotification.notify(member, comment_id: 1) } }
    end

    test "sends one email covering a person's window" do
      member = member_with_daily_comment
      notify(member, 2)

      assert_emails 1 do
        perform_enqueued_jobs { DigestRun.new(window: "daily").call }
      end
    end

    test "sends no email to a person with nothing in the window" do
      member_with_daily_comment

      assert_emails 0 do
        perform_enqueued_jobs { DigestRun.new(window: "daily").call }
      end
    end

    test "lists each notification in the window with a link to it" do
      member = member_with_daily_comment
      notify(member, 2)

      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_equal 2, ActionMailer::Base.deliveries.last.body.to_s.scan("/notifications/").size
    end

    test "records how many notifications the digest held" do
      member = member_with_daily_comment
      notify(member, 2)

      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_equal 2, Digest.last.notifications_count
    end

    test "sends one email when the run happens twice for the same window" do
      member = member_with_daily_comment
      notify(member, 2)

      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_emails 0 do
        perform_enqueued_jobs { DigestRun.new(window: "daily").call }
      end
    end

    test "releases the window when the send fails so it can be sent again" do
      member = member_with_daily_comment
      notify(member, 1)

      DigestMailer.stub(:digest, ->(*) { raise "mail is down" }) do
        assert_raises(RuntimeError) { DigestRun.new(window: "daily").deliver_to_member(member, 7) }
      end

      assert_nil Digest.last
    end

    test "does not send the window again when the run fails after sending" do
      member = member_with_daily_comment
      notify(member, 1)
      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_emails 0 do
        perform_enqueued_jobs { DigestRun.new(window: "daily").call }
      end
    end

    test "sends one email when a second run starts while the first is sending" do
      member = member_with_daily_comment
      notify(member, 1)
      original = DigestMailer.method(:digest)
      overlapped = false

      assert_emails 1 do
        DigestMailer.stub(:digest, lambda { |*args|
          unless overlapped
            overlapped = true
            DigestRun.new(window: "daily").deliver_to_member(member, 7)
          end
          original.call(*args)
        }) do
          perform_enqueued_jobs { DigestRun.new(window: "daily").call }
        end
      end
    end

    test "gathers what the one relation holds and nothing else" do
      member = member_with_daily_comment
      notify(member, 1)

      assert_emails 0 do
        Inbox.stub(:for, ->(*) { Noticed::Notification.none }) do
          perform_enqueued_jobs { DigestRun.new(window: "daily").call }
        end
      end
    end

    test "sends nothing when the notifications carry no account" do
      member = member_with_daily_comment
      notify(member, 1)
      Noticed::Notification.last.update_column(:account_id, nil)

      assert_emails 0 do
        perform_enqueued_jobs { DigestRun.new(window: "daily").call }
      end
    end

    test "reads a person's window through the one resolver" do
      member = member_with_daily_comment
      notify(member, 1)

      assert_emails 0 do
        Channels.stub(:window_of, ->(*) { "immediate" }) do
          perform_enqueued_jobs { DigestRun.new(window: "daily").call }
        end
      end
    end

    test "sends each person's digest in its own job" do
      first = member_with_daily_comment
      notify(first, 1)
      second = Member.create!(email: "other@example.com")
      Preference.create!(member: second, account_id: 7, notification_type: "comment",
        channels: %w[email], digest_window: "daily")
      notify(second, 1)

      assert_enqueued_jobs 2, only: DigestJob do
        DigestRun.new(window: "daily").call
      end
    end

    test "does not query more as a person's types in the window grow" do
      member = member_with_daily_comment
      %w[mention invite].each do |type|
        Preference.create!(member: member, account_id: 7, notification_type: type,
          channels: %w[email], digest_window: "daily")
      end
      notify(member, 1)

      assert_queries_count 9 do
        DigestRun.new(window: "daily").deliver_to_member(member, 7)
      end
    end

    test "does not query more as a person's notifications grow" do
      member = member_with_daily_comment
      notify(member, 6)

      assert_queries_count 9 do
        DigestRun.new(window: "daily").deliver_to_member(member, 7)
      end
    end

    test "sends a weekly window as one email" do
      member = Member.create!(email: "person@example.com")
      Preference.create!(member: member, account_id: 7, notification_type: "comment",
        channels: %w[email], digest_window: "weekly")
      notify(member, 2)

      assert_emails 1 do
        perform_enqueued_jobs { DigestRun.new(window: "weekly").call }
      end
    end

    test "records the window the digest covered" do
      member = member_with_daily_comment
      notify(member, 1)

      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_equal "daily", Digest.last.digest_window
    end

    test "records when the digest was sent" do
      member = member_with_daily_comment
      notify(member, 1)

      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_not_nil Digest.last.sent_at
    end

    test "leaves out a notification the person set to immediate" do
      member = member_with_daily_comment
      Notey.channel(:test, delivery_method: "Noticed::DeliveryMethods::Test")
      Preference.create!(member: member, account_id: 7, notification_type: "mention",
        channels: %w[test], digest_window: "immediate")
      notify(member, 1)
      Current.account_id = 7
      perform_enqueued_jobs { MentionNotification.notify(member, mention_id: 1) }

      perform_enqueued_jobs { DigestRun.new(window: "daily").call }

      assert_equal 1, Digest.last.notifications_count
    end
  end
end
