# frozen_string_literal: true

require "test_helper"

module Notey
  class DigestMailerTest < ActionMailer::TestCase
    teardown { Notey.reset! }

    test "sends from the address the host set" do
      Notey.mailer_sender = "alerts@example.org"

      mail = DigestMailer.digest(Member.create!(email: "person@example.com"), [], "daily")

      assert_equal [ "alerts@example.org" ], mail.from
    end
  end
end
