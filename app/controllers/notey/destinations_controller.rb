# frozen_string_literal: true

module Notey
  class DestinationsController < ApplicationController
    def show
      @channels = Notey.catalog.channels
      @stored = Destination.where(account_id: Current.account_id).index_by(&:channel)
    end

    def update
      result = SaveDestination.new(person: Current.member, account: Current.account_id, values: submitted).call

      return redirect_to destinations_path if result.ok?

      show
      render :show, status: :unprocessable_content
    end

    private

    def submitted
      { destinations: params.fetch(:destinations, {}).permit!.to_h }
    end
  end
end
