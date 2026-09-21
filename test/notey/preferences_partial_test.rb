# frozen_string_literal: true

require "test_helper"

module Notey
  class PreferencesPartialTest < ActionView::TestCase
    helper KeystoneUiHelper

    setup do
      Notey.reset!
      Notey.register_notifier(CommentNotification)
    end

    teardown { Notey.reset! }

    def draw
      render partial: "notey/preferences",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }
    end

    test "draws a checkbox for every registered channel" do
      Notey.channel(:sms)

      draw

      assert_select "input[type=checkbox]", 3
    end

    test "submits a channel under the name the saving reads" do
      draw

      assert_select "input[name='preferences[comment][]'][value=email]"
    end

    test "submits an empty selection when a person picks no channel" do
      draw

      assert_select "input[type=hidden][name='preferences[comment][]']"
    end

    test "labels every channel a person can pick" do
      Notey.channel(:sms)

      draw

      assert_select "label", text: /Sms/
    end
  end
end
