class UserSerializer
  def self.serialize(user)
    new(user).serialize
  end

  def initialize(user)
    @user = user
  end

  def serialize
    {
      name: @user.name,
      country_code: @user.country_code,
      phone_number: @user.phone_number || @user.unconfirmed_phone_number,
      confirmed: @user.phone_number.present?
    }
  end
end
