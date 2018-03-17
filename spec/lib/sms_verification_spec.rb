require 'rails_helper'

describe SmsVerification do
  let(:cache) { double('Cache') }

  before do
    allow(cache).to receive(:write)
  end

  around do |example|
    cached_twilio_account_sid = ENV['TWILIO_ACCOUNT_SID']
    cached_twilio_auth_token = ENV['TWILIO_AUTH_TOKEN']
    ENV['TWILIO_ACCOUNT_SID'] = 'xxx'
    ENV['TWILIO_AUTH_TOKEN'] = 'xxx'
    example.run
    ENV['TWILIO_ACCOUNT_SID'] = cached_twilio_account_sid
    ENV['TWILIO_AUTH_TOKEN'] = cached_twilio_auth_token
  end

  describe '#request_code', :vcr do
    context 'when the request comes from a valid number' do
      let(:client) do
        described_class.new(cache: cache, sender: VALID_SENDER, server_name: 'MyApp', expiration_time: 42)
      end


      context 'and the destination has a valid number' do
        it 'saves the generated code in the cache' do
          expect(cache).to receive(:write).with("sms_verification_+5519123451234", kind_of(Integer), expires_in: 42)
          client.request_code(VALID_RECEIVER)
        end

        it 'makes a request to send the sms' do
          response = client.request_code(VALID_RECEIVER)
          expect(response.body).to match /MyApp Verification Code: \d{4}/
          expect(response.status).to eq 'queued'
        end
      end

      context 'and the destination does not have a valid number' do
        it 'raises a big fat error' do
          expect { client.request_code(INVALID_RECEIVER) }.to raise_error(SmsVerification::Errors::PhoneNumberInvalid)
        end
      end
    end

    context 'and the request does not come from a valid number' do
      it 'raises a big fat error' do
        client = described_class.new(cache: cache, sender: INVALID_SENDER, server_name: 'MyApp', expiration_time: 42)
        expect { client.request_code(VALID_RECEIVER) }.to raise_error(SmsVerification::Errors::PhoneNumberInvalid)
      end
    end
  end

  describe '#verify_code' do
    let(:client) { described_class.new(cache: cache, sender: '+123451234', server_name: 'MyApp', expiration_time: 99) }

    context 'when there is no code cached for the requested phone' do
      it 'returns false' do
        allow(cache).to receive(:read).with('sms_verification_+123451234').and_return nil
        expect(client.verify_code('+123451234', '')).to be false
      end
    end

    context 'when the code differs from the cached one' do
      it 'returns false' do
        allow(cache).to receive(:read).with('sms_verification_+123451234').and_return '0001'
        expect(client.verify_code('+123451234', '0000')).to be false
      end
    end

    context 'when the code is equal to the cached one' do
      before { allow(cache).to receive(:read).with('sms_verification_+123451234').and_return '0001' }

      context 'and it is possible to delete the cached code' do
        it 'deletes the cached code and returns true' do
          allow(cache).to receive(:delete).with('sms_verification_+123451234').and_return true
          expect(client.verify_code('+123451234', '0001')).to be true
        end
      end

      context 'and it is not possible to remove the cached code' do
        it 'tries to delete the cached code and returns false' do
          allow(cache).to receive(:delete).with('sms_verification_+123451234').and_return false
          expect { client.verify_code('+123451234', '0001') }
            .to raise_error(SmsVerification::Errors::UndeletableCachedValue, 'Unable to delete cached value')
        end
      end
    end
  end

  VALID_RECEIVER = '+5519123451234'.freeze
  VALID_SENDER = '+15005550006'.freeze
  INVALID_SENDER = '+15005550001'.freeze
  INVALID_RECEIVER = '+15005550001'.freeze
end
