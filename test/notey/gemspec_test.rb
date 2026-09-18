# frozen_string_literal: true

require "test_helper"

module Notey
  class GemspecTest < ActiveSupport::TestCase
    test "does not make a host install an event pipeline" do
      spec = Gem::Specification.load(File.expand_path("../../notey.gemspec", __dir__))

      pipeline = spec.dependencies.select { |d| d.type == :runtime && d.name.start_with?("event_engine") }

      assert_empty pipeline.map(&:name)
    end

    test "requires a rails new enough to run its migrations" do
      spec = Gem::Specification.load(File.expand_path("../../notey.gemspec", __dir__))
      declared = Dir[File.expand_path("../../db/migrate/*.rb", __dir__)]
                 .flat_map { |file| File.read(file).scan(/ActiveRecord::Migration\[([\d.]+)\]/) }
                 .flatten.map { |version| Gem::Version.new(version) }.max

      floor = spec.dependencies.find { |d| d.name == "rails" }.requirement.requirements
                  .find { |operator, _| operator == ">=" }.last

      assert_operator floor, :>=, declared
    end
  end
end
