class User < ApplicationRecord
  has_secure_password

  validates :name, presence: true
  validates :country_code, presence: true
  validates :phone_number, uniqueness: { scope: :country_code }, if: :phone_number?
  validate :unconfirmed_phone_number_validation

  def confirmed?
    phone_number.present?
  end

  def confirm!(code:)
    return if confirmed?
    return unless confirmation_client.verify_code(full_phone_number, code)
    update(phone_number: unconfirmed_phone_number, unconfirmed_phone_number: nil)
  end

  def full_phone_number
    return country_code + phone_number if confirmed?
    country_code + unconfirmed_phone_number
  end

  def send_confirmation_code!
    return if confirmed?
    confirmation_client.request_code(full_phone_number)
  end

  private

  def confirmation_client
    @confirmation_client ||=
      SmsVerification.new(cache: Rails.cache, server_name: 'TwilioHelloWorld')
  end

  def unconfirmed_phone_number_validation
    return if confirmed? && unconfirmed_phone_number.nil?
    user = User.find_by(country_code: country_code, phone_number: unconfirmed_phone_number)
    return if user.nil? || user == self
    errors.add(:unconfirmed_phone_number, 'Phone number already registered')
  end
end
