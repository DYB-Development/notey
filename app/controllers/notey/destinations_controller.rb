# frozen_string_literal: true

module Notey
  class DestinationsController < ApplicationController
    def show
      @channels = Notey.catalog.channels
    end

    def update
      submitted.each { |channel, attributes| store(channel, attributes) }

      redirect_to destinations_path
    end

    private

    def submitted
      params.fetch(:destinations, {}).permit!.to_h.slice(*Notey.catalog.channels)
    end

    def store(channel, attributes)
      destination = Destination.find_or_initialize_by(account_id: Current.account_id, channel: channel.to_s)

      destination.update(address: attributes["address"], credential: attributes["credential"])
    end
  end
end
