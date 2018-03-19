class UsersController < ApplicationController
  def index
    @users = User.last(10)
    render json: { users: @users.map { |u| UserSerializer.serialize(u) } }
  end

  def create
    command = Commands::CreateUser.new(user_params)
    command.call
    return head :bad_request unless command.success?

    command.result.send_confirmation_code!
    render status: :created, json: { id: command.result.id }
  end

  private

  def user_params
    params.require(:user).permit(:name, :country_code, :phone_number)
  end
end
