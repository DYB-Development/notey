# frozen_string_literal: true

module Notey
  class Destination < ApplicationRecord
    encrypts :credential

    validates :channel, :address, presence: true
  end
end
