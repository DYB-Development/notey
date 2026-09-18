# frozen_string_literal: true

require "test_helper"

module Notey
  class PreferencesTest < ActionDispatch::IntegrationTest
    teardown do
      Current.reset
      Notey.reset!
    end

    test "lists every notification type the app declares" do
      Notey.catalog do
        notification :comment, channels: %w[email], default: %w[email]
        notification :mention, channels: %w[email], default: []
      end
      Current.member = Member.create!
      Current.account_id = 7

      get "/notey/preferences"

      assert_select "body", text: /Mention/
    end
  end
end
