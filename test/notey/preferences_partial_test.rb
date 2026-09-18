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
  end
end
