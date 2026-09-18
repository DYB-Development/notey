require "notey/version"
require "notey/engine"
require "notey/catalog"

module Notey
  def self.catalog(&block)
    @catalog ||= Catalog.new
    @catalog.instance_eval(&block) if block
    @catalog
  end

  def self.reset!
    @catalog = nil
  end
end
