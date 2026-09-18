# frozen_string_literal: true

require "test_helper"

module Notey
  class PreferencesTest < ActionDispatch::IntegrationTest
    teardown do
      Current.reset
      Notey.reset!
    end

    def headers_for(member, account_id: 7)
      { "X-Member-Id" => member.id.to_s, "X-Account-Id" => account_id.to_s }
    end

    test "lists every notification type the app declares" do
      Notey.catalog do
        notification :comment, channels: %w[email], default: %w[email]
        notification :mention, channels: %w[email], default: []
      end
      member = Member.create!

      get "/notey/preferences", headers: headers_for(member)

      assert_select "body", text: /Mention/
    end

    test "keeps a channel choice after a reload" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: %w[email] }
      member = Member.create!

      patch "/notey/preferences", params: { preferences: { comment: %w[sms] } }, headers: headers_for(member)
      get "/notey/preferences", headers: headers_for(member)

      assert_select "input[type=checkbox][value=sms][checked]"
    end

    test "shows choices for the account the person is in and not another" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: [] }
      member = Member.create!

      patch "/notey/preferences", params: { preferences: { comment: %w[sms] } }, headers: headers_for(member, account_id: 7)
      get "/notey/preferences", headers: headers_for(member, account_id: 8)

      assert_select "input[type=checkbox][value=sms][checked]", false
    end

    test "preselects the default for a person who has set nothing" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: %w[email] }

      get "/notey/preferences", headers: headers_for(Member.create!)

      assert_select "input[type=checkbox][value=email][checked]"
    end

    test "refuses a channel the catalog does not offer for that type" do
      Notey.catalog { notification :comment, channels: %w[email], default: [] }
      member = Member.create!

      patch "/notey/preferences", params: { preferences: { comment: %w[sms] } }, headers: headers_for(member)

      assert_empty Preference.last&.channels || []
    end

    test "keeps the window a person chose for a notification type" do
      Notey.catalog { notification :comment, channels: %w[email], default: %w[email] }
      member = Member.create!

      patch "/notey/preferences",
        params: { preferences: { comment: %w[email] }, windows: { comment: "daily" } },
        headers: headers_for(member)

      assert_equal "daily", Preference.last.digest_window
    end

    test "ignores a notification type the catalog does not declare" do
      Notey.catalog { notification :comment, channels: %w[email], default: %w[email] }

      patch "/notey/preferences",
        params: { preferences: { invented: %w[email] } },
        headers: headers_for(Member.create!)

      assert_nil Preference.last
    end
  end
end
