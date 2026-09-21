# frozen_string_literal: true

class CommentNotification < Notey::Notification
  notey_type :comment

  required_params :comment_id

  def body
    "Comment #{params[:comment_id]} was left for you"
  end
end
