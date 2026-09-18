# frozen_string_literal: true

require "test_helper"

module Notey
  class SavePreferencesTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

    test "keeps the channels a person chose for a type" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: [] }
      member = Member.create!

      SavePreferences.new(person: member, account: 7, values: { preferences: { "comment" => %w[sms] } }).call

      assert_equal %w[sms], Preference.last.channels
    end

    test "refuses a window notey does not send on" do
      Notey.catalog { notification :comment, channels: %w[email], default: [] }

      result = SavePreferences.new(person: Member.create!, account: 7,
        values: { preferences: { "comment" => %w[email] }, windows: { "comment" => "fortnightly" } }).call

      assert_not result.ok?
    end
  end
end
