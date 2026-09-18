# frozen_string_literal: true

module Notey
  class DigestJob < ApplicationJob
    def perform(member, account_id, window)
      DigestRun.new(window: window).deliver_to_member(member, account_id)
    end
  end
end
