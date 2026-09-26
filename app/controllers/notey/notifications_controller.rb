# frozen_string_literal: true

module Notey
  class NotificationsController < ApplicationController
    PER_PAGE = 25

    def index
      @notifications = inbox.includes(:event).order(created_at: :desc).limit(PER_PAGE)

      Noticed::Notification.where(id: @notifications.map(&:id)).unseen.mark_as_seen
    end

    def update
      MarkRead.new(person: Current.member, account: Current.account_id, values: { read: params[:id] }).call

      redirect_to notifications_path
    end

    private

    def inbox
      Inbox.for(Current.member, account_id: Current.account_id)
    end
  end
end
