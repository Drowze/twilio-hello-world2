class SmsVerification
  def initialize(cache:, sender: nil, server_name:, expiration_time: 900)
    @cache = cache
    @sender = sender || ENV.fetch('TWILIO_DEFAULT_SENDER')
    @server_name = server_name
    @expiration_time = expiration_time
  end

  def request_code(phone)
    otp = generate_otp
    @cache.write(caching_key(phone), otp, expires_in: @expiration_time)
    send_sms(from: @sender, to: phone, body: body_message(@server_name, otp))
  rescue Twilio::REST::RestError
    raise Errors::PhoneNumberInvalid
  end

  def verify_code(phone, otp)
    cached_otp = @cache.read(caching_key(phone))
    return false if cached_otp.nil?
    return false unless cached_otp.to_s == otp.to_s
    return true if @cache.delete(caching_key(phone))
    raise Errors::UndeletableCachedValue, 'Unable to delete cached value'
  end

  private

  def caching_key(phone)
    "sms_verification_#{phone}"
  end

  def body_message(server_name, otp)
    "#{server_name} Verification Code: #{otp}"
  end

  def send_sms(from:, to:, body:)
    sms_client.api.account.messages.create(from: from, to: to, body: body)
  end

  def generate_otp
    SecureRandom.random_number(1000..9999)
  end

  def sms_client
    @sms_client ||= Twilio::REST::Client.new(
      ENV.fetch('TWILIO_ACCOUNT_SID'),
      ENV.fetch('TWILIO_AUTH_TOKEN')
    )
  end
end
