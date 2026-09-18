# frozen_string_literal: true

module Notey
  class Refusal
    attr_reader :message

    def initialize(message)
      @message = message
    end

    def ok? = false
  end
end
