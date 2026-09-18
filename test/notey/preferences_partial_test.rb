# frozen_string_literal: true

require "test_helper"

module Notey
  class PreferencesPartialTest < ActionView::TestCase
    helper KeystoneUiHelper

    teardown { Notey.reset! }

    test "draws a checkbox for every channel a type offers" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: [] }

      render partial: "notey/preferences",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[type=checkbox]", 2
    end

    test "submits a channel under the name the saving reads" do
      Notey.catalog { notification :comment, channels: %w[email], default: [] }

      render partial: "notey/preferences",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[name='preferences[comment][]'][value=email]"
    end

    test "submits an empty selection when a person picks no channel" do
      Notey.catalog { notification :comment, channels: %w[email], default: [] }

      render partial: "notey/preferences",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[type=hidden][name='preferences[comment][]']"
    end

    test "labels every channel a person can pick" do
      Notey.catalog { notification :comment, channels: %w[email sms], default: [] }

      render partial: "notey/preferences",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "label", text: /Sms/
    end
  end
end
