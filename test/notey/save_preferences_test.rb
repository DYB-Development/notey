# frozen_string_literal: true

require "test_helper"

module Notey
  class SavePreferencesTest < ActiveSupport::TestCase
    teardown do
      Current.reset
      Notey.reset!
    end

    test "keeps the channels a person chose for a type" do
      Notey.channel(:sms)
      member = Member.create!

      SavePreferences.new(person: member, account: 7, values: { preferences: { "comment" => %w[sms] } }).call

      assert_equal %w[sms], Preference.last.channels
    end

    test "turns every channel off when the form sends none" do
      Notey.catalog { notification :comment, channels: %w[email], default: %w[email] }
      member = Member.create!

      SavePreferences.new(person: member, account: 7,
        values: { preferences: { "comment" => [ "" ] } }).call

      assert_empty Preference.last.channels
    end

    test "refuses a window notey does not send on" do
      Notey.catalog { notification :comment, channels: %w[email], default: [] }

      result = SavePreferences.new(person: Member.create!, account: 7,
        values: { preferences: { "comment" => %w[email] }, windows: { "comment" => "fortnightly" } }).call

      assert_not result.ok?
    end
  end
end
