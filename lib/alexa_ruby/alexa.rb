module AlexaRuby
  # Main processing class, parses request from Amazon Alexa and
  # initialize new response object
  class Alexa
    attr_reader :request, :response

    # Initialize new Alexa assistant
    #
    # @param request [Hash] request from Amazon Alexa web service
    # @param opts [Hash] additional options:
    #   :disable_validations [Boolean] disables request validation if true
    def initialize(request, opts)
      @req = request
      @opts = opts
      invalid_request_exception if invalid_request?
      @request = define_request
      raise ArgumentError, 'Unknown type of Alexa request' if @request.nil?
      @response = Response.new(@request.type, @request.version)
    end

    private

    # Check if validations are enabled
    #
    # @return [Boolean]
    def validations_enabled?
      !@opts[:disable_validations] || @opts[:disable_validations].nil?
    end

    # Check if it is an invalid request
    #
    # @return [Boolean]
    def invalid_request?
      @req[:version].nil? || @req[:request].nil? if validations_enabled?
    end

    # Request structure isn't valid, raise exception
    def invalid_request_exception
      raise ArgumentError,
            'Invalid request structure, ' \
            'please, refer to the Amazon Alexa manual: ' \
            'https://developer.amazon.com/public/solutions' \
            '/alexa/alexa-skills-kit/docs/alexa-skills-kit-interface-reference'
    end

    # Initialize proper request object
    #
    # @return [Object] request object
    def define_request
      case @req[:request][:type]
      when /Launch/
        LaunchRequest.new(@req)
      when /Intent/
        IntentRequest.new(@req)
      when /SessionEnded/
        SessionEndedRequest.new(@req)
      when /AudioPlayer/, /PlaybackController/
        AudioPlayerRequest.new(@req)
      end
    end
  end
end
