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

    def preference_queries(&block)
      count = 0
      counter = lambda do |*, payload|
        count += 1 if payload[:name] == "Notey::Preference Load" && payload[:sql].to_s.include?("notey_preferences")
      end
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end

    test "reads a person's preferences once however many types the application has" do
      member = Member.create!

      queries = preference_queries { get "/notey/preferences", headers: headers_for(member) }

      assert_equal 1, queries
    end

    test "lists every notification type the application has" do
      member = Member.create!

      get "/notey/preferences", headers: headers_for(member)

      assert_select "body", text: /Mention/
    end

    test "keeps a channel choice after a reload" do
      Notey.channel(:sms)
      member = Member.create!

      patch "/notey/preferences", params: { preferences: { comment: %w[sms] } }, headers: headers_for(member)
      get "/notey/preferences", headers: headers_for(member)

      assert_select "input[type=checkbox][value=sms][checked]"
    end

    test "shows choices for the account the person is in and not another" do
      Notey.channel(:sms)
      member = Member.create!

      patch "/notey/preferences", params: { preferences: { comment: %w[sms] } }, headers: headers_for(member, account_id: 7)
      get "/notey/preferences", headers: headers_for(member, account_id: 8)

      assert_select "input[type=checkbox][value=sms][checked]", false
    end

    test "preselects the default for a person who has set nothing" do
      get "/notey/preferences", headers: headers_for(Member.create!)

      assert_select "input[type=checkbox][value=email][checked]"
    end

    test "refuses a channel the application does not have" do
      member = Member.create!

      patch "/notey/preferences", params: { preferences: { comment: %w[sms] } }, headers: headers_for(member)

      assert_empty Preference.last&.channels || []
    end

    test "keeps the window a person chose for a notification type" do
      member = Member.create!

      patch "/notey/preferences",
        params: { preferences: { comment: %w[email] }, windows: { comment: "daily" } },
        headers: headers_for(member)

      assert_equal "daily", Preference.last.digest_window
    end

    test "ignores a notification type the application does not have" do
      patch "/notey/preferences",
        params: { preferences: { invented: %w[email] } },
        headers: headers_for(Member.create!)

      assert_nil Preference.last
    end

    test "shows the page again when a preference does not save" do
      patch "/notey/preferences",
        params: { preferences: { comment: %w[email] }, windows: { comment: "fortnightly" } },
        headers: headers_for(Member.create!)

      assert_response :unprocessable_content
    end
  end
end
