# frozen_string_literal: true

require "test_helper"

module Notey
  class SchemaTest < ActiveSupport::TestCase
    test "indexes the digest window the run filters on" do
      indexed = ActiveRecord::Base.connection.indexes(:notey_preferences).flat_map(&:columns)

      assert_includes indexed, "digest_window"
    end
  end
end
