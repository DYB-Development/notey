class ApplicationController < ActionController::Base
  before_action :set_notey_current

  private

  def set_notey_current
    Notey::Current.member = Member.find_by(id: request.headers["X-Member-Id"] || params[:member_id])
    Notey::Current.account_id = request.headers["X-Account-Id"] || params[:account_id]
  end
end
