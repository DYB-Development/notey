require "notey/version"
require "notey/engine"
require "notey/catalog"
require "notey/channels"
require "notey/event_subscriber"
require "notey/inbox"
require "notey/digest_run"

module Notey
  class << self
    attr_writer :notification_url
  end

  def self.notification_url
    @notification_url || ->(notification) { nil }
  end

  def self.deliver_on(event_name, notifier)
    event_notifiers[event_name.to_s] = notifier
    EventSubscriber.subscribes_to(event_name)
  end

  def self.notifier_for(event_name)
    event_notifiers[event_name.to_s]
  end

  def self.event_notifiers
    @event_notifiers ||= {}
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
    @event_notifiers = nil
  end
end
