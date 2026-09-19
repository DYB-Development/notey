# frozen_string_literal: true

module Notey
  class Destination < ApplicationRecord
    belongs_to :member, polymorphic: true, optional: true

    encrypts :credential

    validates :channel, :address, presence: true
  end
end
