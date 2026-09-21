require "notey/version"
require "notey/engine"
require "notey/channels"
require "notey/destinations"
require "notey/inbox"
require "notey/digest_run"
require "notey/records_attempt"

module Notey
  ALWAYS_ON_DELIVERY = { "email" => "Notey::Email", "in_app" => "Notey::InApp" }.freeze
  ALWAYS_ON = ALWAYS_ON_DELIVERY.keys.freeze

  RegisteredChannel = Struct.new(:name, :delivery_method, :addressed, keyword_init: true) do
    def addressed?
      addressed == true
    end
  end

  class MissingSender < StandardError; end

  class << self
    attr_writer :notification_url, :mailer_sender
  end

  def self.mailer_sender
    @mailer_sender
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

  def self.channels
    registered_channels.map(&:name)
  end

  def self.notification_types
    notifiers.filter_map(&:notey_notification_type).uniq
  end

  def self.default_channels
    channels & ALWAYS_ON
  end

  def self.channel(name, delivery_method: nil, addressed: false)
    host_channels << RegisteredChannel.new(
      name: name.to_s, delivery_method: delivery_method, addressed: addressed
    )
  end

  def self.registered_channels
    always_on_channels + host_channels
  end

  def self.addressed_channels
    registered_channels.select(&:addressed?).map(&:name)
  end

  def self.always_on_channels
    ALWAYS_ON_DELIVERY.filter_map do |name, delivery_method|
      next if host_channels.any? { |channel| channel.name == name }

      RegisteredChannel.new(name: name, delivery_method: delivery_method)
    end
  end

  def self.host_channels
    @host_channels ||= []
  end

  def self.forget_notifiers
    @notifiers = []
  end

  def self.check!
    check_sender!
  end

  def self.check_sender!
    return if mailer_sender.present?

    raise MissingSender, "notey sends digests by email and no mailer_sender is set"
  end

  def self.sends(notification_type, on:, addressed: false)
    lambda do
      decision = Channels.decision_for(recipient, notification_type, account_id: event.account_id)

      next false unless decision.window == "immediate" && decision.channels.include?(on.to_s)
      next true unless addressed

      Destinations.for(event.account_id, on, member: recipient).present?
    end
  end

  def self.reset!
    @host_channels = nil
    forget_notifiers
  end
end
