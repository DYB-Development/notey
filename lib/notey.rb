require "notey/version"
require "notey/engine"
require "notey/catalog"
require "notey/channels"
require "notey/destinations"
require "notey/event_delivery"
require "notey/inbox"
require "notey/digest_run"

module Notey
  class UndeclaredType < StandardError; end
  class UndeliverableChannel < StandardError; end

  class << self
    attr_writer :notification_url
  end

  def self.notification_url
    @notification_url || ->(notification) { nil }
  end

  def self.register_notifier(notifier)
    notifiers << notifier unless notifiers.include?(notifier)
  end

  def self.notifiers
    @notifiers ||= []
  end

  def self.check!
    return if catalog.notifications.empty?

    check_declared_types!
    check_deliverable_channels!
  end

  def self.check_deliverable_channels!
    delivered = notifiers.flat_map { |notifier| notifier.delivery_methods.keys.map(&:to_s) }.uniq

    (catalog.channels - delivered).each do |channel|
      raise UndeliverableChannel, "the catalog offers the channel #{channel}, which no notifier delivers on"
    end
  end

  def self.check_declared_types!
    notifiers.each do |notifier|
      notification_type = notifier.notey_notification_type
      next if notification_type.nil? || catalog.declared?(notification_type)

      raise UndeclaredType,
        "#{notifier} declares the notification type #{notification_type}, which the catalog does not hold"
    end
  end

  def self.destination_address(channel)
    -> { Destinations.for(event.account_id, channel)&.address }
  end

  def self.addressed(channel)
    -> { Destinations.for(event.account_id, channel).present? }
  end

  def self.deliver_on(event_name, notifier)
    event_notifiers[event_name.to_s] = notifier
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
      decision = Channels.decision_for(recipient, notification_type, account_id: event.account_id)

      decision.window == "immediate" && decision.channels.include?(on.to_s)
    end
  end

  def self.reset!
    @catalog = nil
    @event_notifiers = nil
  end
end
