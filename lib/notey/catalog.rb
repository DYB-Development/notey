# frozen_string_literal: true

module Notey
  class Catalog
    def initialize
      @defaults = {}
    end

    def notification(name, default: [])
      @defaults[name.to_s] = Array(default).map(&:to_s)
    end

    def default_channels_for(notification_type)
      @defaults.fetch(notification_type.to_s, [])
    end
  end
end
