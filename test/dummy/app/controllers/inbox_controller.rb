class InboxController < ApplicationController
  helper KeystoneUiHelper

  def show
  end

  def update
    Notey::MarkRead.new(person: Notey::Current.member, account: Notey::Current.account_id, values: params).call

    redirect_to inbox_path
  end
end
