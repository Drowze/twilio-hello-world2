module Commands
  class CreateUser
    def initialize(user_params)
      @user_params = user_params
    end

    def call
      @user = User.new(normalized_parameters)
      @user.save!
    rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
      raise Errors::PhoneNumberRegistered
    end

    def result
      @user
    end

    def success?
      @user.persisted?
    end

    private

    def normalized_parameters
      @user_params
        .except(:phone_number)
        .merge(unconfirmed_phone_number: @user_params[:phone_number], password: SecureRandom.hex)
    end
  end
end
