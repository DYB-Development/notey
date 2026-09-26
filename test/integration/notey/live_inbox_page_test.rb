# frozen_string_literal: true

require "test_helper"

module Notey
  class LiveInboxPageTest < ActionDispatch::IntegrationTest
    teardown { Notey.reset! }

    test "a host page shows the inbox subscribed to live updates with Turbo loaded" do
      Notey.live_updates = true
      member = Member.create!(email: "person@example.com")

      get "/inbox", headers: { "X-Member-Id" => member.id.to_s, "X-Account-Id" => "7" }

      assert_select "script[src*=turbo]"
      assert_select "turbo-cable-stream-source"
    end
  end
end
