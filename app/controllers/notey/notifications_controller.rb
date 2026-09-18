# frozen_string_literal: true

module Notey
  class NotificationsController < ApplicationController
    def index
      @notifications = inbox.order(created_at: :desc)
      @unread_count = inbox.unread.count

      inbox.unseen.mark_as_seen
    end

    def update
      inbox.find(params[:id]).mark_as_read!

      redirect_to notifications_path
    end

    private

    def inbox
      Inbox.for(Current.member, account_id: Current.account_id)
    end
  end
end
