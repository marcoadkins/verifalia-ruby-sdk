require 'spec_helper'

describe Verifalia::REST::EmailValidations do
  let(:config) { { hosts: ["https://api.fake.com"], api_version: "v" } }

  describe '#initialize' do

    it 'create RestClient::Resource with correct parameters' do
      api_url = "#{config[:hosts][0]}/#{config[:api_version]}/email-validations"
      opts = {
        user: 'someSid',
        password: 'someToken',
        headers: { content_type: :json, user_agent: "verifalia-rest-client/ruby/#{Verifalia::VERSION}" }
      }

      expect(RestClient::Resource).to receive(:new).with(api_url, opts)
      Verifalia::REST::EmailValidations.new(config, 'someSid', 'someToken')
    end

    it 'should shuffle hosts array' do
      expect(config[:hosts]).to receive(:shuffle).and_return(["https://api.fake.com"])
      Verifalia::REST::EmailValidations.new(config, 'someSid', 'someToken')
    end

    it 'associate RestClient::Resource to @resource' do
      resource = double()
      allow(RestClient::Resource).to receive(:new).and_return(resource)
      email_validations = Verifalia::REST::EmailValidations.new(config, 'someSid', 'someToken')
      expect(email_validations.instance_variable_get('@resource')).to eq(resource)
    end

    it 'associate :unique_id to @unique_id' do
      unique_id = double()
      email_validations = Verifalia::REST::EmailValidations.new(config, 'someSid', 'someToken', unique_id: unique_id)
      expect(email_validations.instance_variable_get('@unique_id')).to eq(unique_id)
    end

  end

  context 'initialized' do
    let(:resource) { double().as_null_object }
    let(:response) { double().as_null_object }
    let(:response_json) { double().as_null_object }
    before(:each) do
      @email_validations = Verifalia::REST::EmailValidations.new(config, 'someSid', 'someToken')
      @email_validations.instance_variable_set('@resource', resource)
    end

    describe '#verify' do

      it 'raise ArgumentError with nil emails' do
        expect{ @email_validations.verify(nil) }.to raise_error(ArgumentError)
      end

      it 'raise ArgumentError with empty emails' do
        expect{ @email_validations.verify([]) }.to raise_error(ArgumentError)
      end

      it 'raise ArgumentError with unvalid options' do
        emails = ['first', 'second']
        expect{ @email_validations.verify(emails, 'a string') }.to raise_error(ArgumentError)
      end


      it 'raise ArgumentError with with hash array parameters with invalid value' do
        inputs = [
          {
            fakeKey: 'fake second'
          },
          {
            fakeKey: 'fake second'
          }
        ]
        expect{ @email_validations.verify(inputs) }.to raise_error(ArgumentError)
      end

      it 'call #post on @resources with string array parameters' do
        emails = ['first', 'second']
        data = emails.map { |email| { inputData: email }}
        content = { entries: data }.to_json
        expect(resource).to receive(:post).with(content).and_return(response)
        expect(JSON).to receive(:parse).with(response).and_return(response_json)
        @email_validations.verify(emails)
      end

      it 'call #post on @resources with string array parameters and options' do
        emails = ['first', 'second']
        options = { option_1: 'test' }
        data = emails.map { |email| { inputData: email }}
        content = { entries: data, option_1: 'test' }.to_json
        expect(resource).to receive(:post).with(content).and_return(response)
        expect(JSON).to receive(:parse).with(response).and_return(response_json)
        @email_validations.verify(emails, options)
      end

      it 'call #post on @resources with hash array parameters with valid value' do
        data = [
          {
            inputData: 'first'
          },
          {
            inputData: 'second'
          }
        ]
        content = { entries: data }.to_json
        expect(resource).to receive(:post).with(content).and_return(response)
        expect(JSON).to receive(:parse).with(response).and_return(response_json)
        @email_validations.verify(data)
      end

      it 'associate @unique_id' do
        emails = ['first', 'second']
        unique_id = 'fake'
        parsed = double()
        expect(JSON).to receive(:parse).and_return(parsed)
        expect(parsed).to receive(:[]).with("uniqueID").and_return(unique_id)
        @email_validations.verify(emails)
        expect(@email_validations.instance_variable_get('@unique_id')).to eq(unique_id)
      end

      it 'return @unique_id' do
        emails = ['first', 'second']
        unique_id = 'fake'
        parsed = double()
        expect(JSON).to receive(:parse).and_return(parsed)
        expect(parsed).to receive(:[]).with("uniqueID").and_return(unique_id)
        result = @email_validations.verify(emails)
        expect(result).to eq(unique_id)
      end

      context 'request failed' do

        it 'raise exception, call #compute_error and return false' do
          emails = ['first', 'second']
          expect(resource).to receive(:post).and_raise(RestClient::Exception)
          result = @email_validations.verify(emails)
          expect(result).to eq(false)
          expect(@email_validations.error).to eq(:internal_server_error)
        end

        it 'raise exception, call #compute_error and return correct error' do
          emails = ['first', 'second']
          exception = RestClient::Exception.new(nil, 402)
          expect(resource).to receive(:post).and_raise(exception)
          result = @email_validations.verify(emails)
          expect(result).to eq(false)
          expect(@email_validations.error).to eq(:payment_required)
        end
      end
    end

    describe '#query' do
      it 'raise ArgumentError without @unique_id' do
        expect{ @email_validations.query }.to raise_error(ArgumentError)
      end

      context 'with @unique_id' do
        before(:each) do
          @email_validations.instance_variable_set('@unique_id', 'fake')
        end

        it 'call #get on @resource[@uniqueId] with correct parameters' do
          request = double()
          expect(resource).to receive(:[]).with('fake').and_return(request)
          expect(request).to receive(:get).and_return(double().as_null_object)
          expect(JSON).to receive(:parse)
          @email_validations.query
        end

        it 'return parsed json' do
          parsed = double()
          expect(resource).to receive(:[]).with('fake')
          expect(JSON).to receive(:parse).and_return(parsed)
          result = @email_validations.query
          expect(result).to eq(parsed)
        end

        context 'with completion' do
          it 'call #get on @resource[@uniqueId] multiple time' do
            request = double()
            expect(resource).to receive(:[]).with('fake').and_return(request)
            expect(request).to receive(:get).twice.and_return(double().as_null_object)
            allow(JSON).to receive(:parse)
            @email_validations.query(wait_for_completion: true, completion_max_retry: 2)
          end
        end

        context 'request failed' do

          it 'raise exception, call #compute_error and return false' do
            request = double()
            expect(resource).to receive(:[]).with('fake').and_return(request)
            expect(request).to receive(:get).and_raise(RestClient::Exception)
            expect(@email_validations).to receive(:compute_error).and_return(double())
            result = @email_validations.query
            expect(result).to eq(false)
          end
        end

      end
    end

    describe '#completed?' do
      let(:response) { double().as_null_object }

      before(:each) do
        @email_validations.instance_variable_set('@response', response)
      end


      context 'with 202 http code response' do
        before(:each) do
          allow(response).to receive(:code).and_return(202)
          allow(@email_validations).to receive(:query).and_return({ "progress" => nil })
        end

        it 'should return false' do
          expect(@email_validations.completed?).to be false
        end
      end

      context 'with 200 http code response' do
        let(:completed_query) do
          { "progress"=> { "noOfTotalEntries" => 1, "noOfCompletedEntries" => 1 } }
        end
        let(:incompleted_query) do
          { "progress"=> { "noOfTotalEntries" => 0, "noOfCompletedEntries" => 1 } }
        end

        before(:each) do
          allow(response).to receive(:code).and_return(200)
        end

        it 'should return true' do
          expect(@email_validations.completed?).to be true
        end
      end
    end

    describe '#destroy' do
      it 'raise ArgumentError without @unique_id' do
        expect{ @email_validations.destroy }.to raise_error(ArgumentError)
      end

      context 'with @unique_id' do
        before(:each) do
          @email_validations.instance_variable_set('@unique_id', 'fake')
        end

        it 'call #delete on @resource[@uniqueId]' do
          request = double()
          expect(resource).to receive(:[]).with('fake').and_return(request)
          expect(request).to receive(:delete).and_return(double().as_null_object)
          @email_validations.destroy
        end

        it 'clear @response, @unique_id and @error' do
          request = double()
          expect(resource).to receive(:[]).with('fake').and_return(request)
          expect(request).to receive(:delete).and_return(double().as_null_object)
          @email_validations.destroy
          expect(@email_validations.instance_variable_get('@response')).to eq(nil)
          expect(@email_validations.instance_variable_get('@unique_id')).to eq(nil)
          expect(@email_validations.instance_variable_get('@error')).to eq(nil)
        end
      end
    end
  end

end
