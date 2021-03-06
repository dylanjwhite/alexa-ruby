require_relative '../spec_helper'

describe 'AlexaRuby::Response' do
  before do
    @req_path = 'spec/fixtures/request'
    @resp_path = 'spec/fixtures/response'
  end

  describe 'Speech' do
    before do
      @json = File.read("#{@req_path}/launch_request.json")
      @alexa = AlexaRuby.new(@json)
    end

    it 'should add plain text output to response' do
      @alexa.response.tell('Test')
      resp = Oj.load(@alexa.response.json, symbol_keys: true)
      resp[:response][:outputSpeech][:type].must_equal 'PlainText'
      resp[:response][:outputSpeech][:text].must_equal 'Test'
      resp[:response][:outputSpeech][:ssml].must_be_nil
    end

    it 'should add SSML output to response' do
      @alexa.response.tell('Test', nil, true)
      resp = Oj.load(@alexa.response.json, symbol_keys: true)
      resp[:response][:outputSpeech][:type].must_equal 'SSML'
      resp[:response][:outputSpeech][:ssml].must_equal '<speak>Test</speak>'
      resp[:response][:outputSpeech][:text].must_be_nil
    end

    it 'should add output with repromt' do
      @alexa.response.tell('Test', 'One more test')
      resp = Oj.load(@alexa.response.json, symbol_keys: true)
      resp[:response][:outputSpeech][:type].must_equal 'PlainText'
      resp[:response][:outputSpeech][:text].must_equal 'Test'
      resp[:response][:outputSpeech][:ssml].must_be_nil
      repromt = resp[:response][:reprompt][:outputSpeech]
      repromt[:type].must_equal 'PlainText'
      repromt[:text].must_equal 'One more test'
      repromt[:ssml].must_be_nil
    end

    it 'should add output speech and return JSON' do
      sample = Oj.load(
        File.read("#{@resp_path}/sample_response.json"),
        symbol_keys: true
      )
      sample[:response][:reprompt] = {
        outputSpeech: {
          type: 'PlainText',
          text: 'Test'
        }
      }
      @alexa.response.tell!('Test', 'Test').must_equal Oj.to_json(sample)
    end

    it 'should add output speech without closing session' do
      @alexa.response.ask('Test')
      resp = Oj.load(@alexa.response.json, symbol_keys: true)
      resp[:response][:shouldEndSession].must_equal false
    end

    it 'should add output speech without closing session and return JSON' do
      sample = Oj.load(
        File.read("#{@resp_path}/sample_response.json"),
        symbol_keys: true
      )
      sample[:response][:shouldEndSession] = false
      @alexa.response.ask!('Test').must_equal Oj.to_json(sample)
    end
  end
end
