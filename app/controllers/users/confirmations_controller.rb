class Users::ConfirmationsController < ApplicationController
  def create
    return head :bad_request if target_user.confirmed?

    target_user.send_confirmation_code!
    head :created
  end

  def accept
    code = params.require(:code)
    return head :bad_request unless target_user.confirm!(code: code)
    head :ok
  end

  private

  def target_user
    User.find(params.require(:user_id))
  end
end
