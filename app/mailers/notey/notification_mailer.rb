# frozen_string_literal: true

module Notey
  class NotificationMailer < ApplicationMailer
    def notification
      @notification = params[:notification]

      mail(to: params[:recipient].email, subject: @notification.event.title)
    end
  end
end
