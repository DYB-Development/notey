# frozen_string_literal: true

module Notey
  class DestinationsController < ApplicationController
    def show
      @channels = Notey.catalog.channels
    end

    def update
      saved = submitted.map { |channel, attributes| store(channel, attributes) }

      return redirect_to destinations_path if saved.all?

      show
      render :show, status: :unprocessable_content
    end

    private

    def submitted
      params.fetch(:destinations, {}).permit!.to_h.slice(*Notey.catalog.channels)
    end

    def store(channel, attributes)
      destination = Destination.find_or_initialize_by(account_id: Current.account_id, channel: channel.to_s)

      changes = { address: attributes["address"] }
      changes[:credential] = attributes["credential"] if attributes["credential"].present?

      destination.update(changes)
    end
  end
end
