require "notey/version"
require "notey/engine"
require "notey/catalog"

module Notey
  def self.catalog(&block)
    @catalog ||= Catalog.new
    @catalog.instance_eval(&block) if block
    @catalog
  end

  def self.wanted(notification_type, on:)
    -> { recipient.wants?(notification_type, on: on, account_id: event.account_id) }
  end

  def self.reset!
    @catalog = nil
  end
end
