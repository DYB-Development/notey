# frozen_string_literal: true

module Notey
  class SaveMyDestination < SaveDestination
    private

    def owner
      @person
    end
  end
end
