# frozen_string_literal: true

require "test_helper"

module Notey
  class DestinationsPartialTest < ActionView::TestCase
    helper KeystoneUiHelper
    helper Notey::ApplicationHelper

    teardown { Notey.reset! }

    test "draws an address box for every channel the catalog offers" do
      Notey.catalog { notification :comment, channels: %w[webhook slack], default: [] }

      render partial: "notey/destinations",
        locals: { person: Member.create!, account: 7, selection: {}, submit_url: "/settings" }

      assert_select "input[name$='[address]']", 2
    end
  end
end
