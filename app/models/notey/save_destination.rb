# frozen_string_literal: true

module Notey
  class SaveDestination
    def initialize(values:, person: nil, account: nil)
      @person = person
      @account_id = account.respond_to?(:id) ? account.id : account
      @values = values
    end

    def call
      refusal = submitted.filter_map { |channel, attributes| store(channel, attributes) }.first

      refusal || Kept.new
    end

    private

    def owner
      nil
    end

    def submitted
      @values.fetch(:destinations, {}).slice(*Notey.catalog.channels)
    end

    def store(channel, attributes)
      destination = Destination.find_or_initialize_by(
        account_id: @account_id, channel: channel.to_s, member: owner
      )
      destination.address = attributes["address"]
      destination.credential = attributes["credential"] if attributes["credential"].present?

      Refusal.new(destination.errors.full_messages.first) unless destination.save
    end
  end
end
