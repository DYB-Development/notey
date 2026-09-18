require "notey/version"
require "notey/engine"
require "notey/catalog"
require "notey/digest_run"

module Notey
  class << self
    attr_writer :notification_url
  end

  def self.notification_url
    @notification_url || ->(notification) { nil }
  end

  def self.catalog(&block)
    @catalog ||= Catalog.new
    @catalog.instance_eval(&block) if block
    @catalog
  end

  def self.wanted(notification_type, on:)
    lambda do
      account_id = event.account_id

      recipient.digest_window_for(notification_type, account_id: account_id) == "immediate" &&
        recipient.wants?(notification_type, on: on, account_id: account_id)
    end
  end

  def self.reset!
    @catalog = nil
  end
end
