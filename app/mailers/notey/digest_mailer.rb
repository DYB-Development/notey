# frozen_string_literal: true

module Notey
  class DigestMailer < ApplicationMailer
    def digest(member, notifications, window)
      @notifications = notifications
      @window = window

      mail(to: member.email, subject: "Your #{window} notifications")
    end
  end
end
