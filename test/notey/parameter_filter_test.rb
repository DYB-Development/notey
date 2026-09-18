# frozen_string_literal: true

require "test_helper"

module Notey
  class ParameterFilterTest < ActiveSupport::TestCase
    test "keeps a posted credential out of the request log" do
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

      filtered = filter.filter("destinations" => { "recording" => { "credential" => "sekrit" } })

      assert_equal "[FILTERED]", filtered["destinations"]["recording"]["credential"]
    end
  end
end
