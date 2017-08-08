require 'base64'
require 'httparty'
require 'openssl'

module AlexaRuby
  # SSL certificates validator
  class Certificates
    # Setup new certificates chain
    #
    # @param certificates_chain_url [String] SSL certificates chain URL
    # @param signature [String] HTTP request signature
    # @param request [String] plain HTTP request body
    def initialize(certificates_chain_url, signature, request)
      download_certificates(certificates_chain_url)
      @signature = signature
      @request = request
    end

    # Check if it is a valid certificates chain and request signature
    #
    # @return [Boolean]
    def valid?
      raise ArgumentError, 'Inactive Amazon SSL certificate' unless active?
      raise ArgumentError, 'Inactive host in SSL certificate' unless amazon?
      raise ArgumentError, 'Signature and request mismatch' unless verified?
      true
    end

    private

    # Download SSL certificates chain from Amazon URL
    #
    # @param certificates_chain_url [String] SSL certificates chain URL
    def download_certificates(certificates_chain_url)
      resp = HTTParty.get(certificates_chain_url)
      raise ArgumentError, 'Invalid certificates chain' unless resp.code == 200
      @cert = OpenSSL::X509::Certificate.new(resp.body)
    end

    # Check if it is an active certificate
    #
    # @return [Boolean]
    def active?
      now = Time.now
      @cert.not_before < now && @cert.not_after > now
    end

    # Check if Subject Alternative Names includes Amazon domain name
    #
    # @return [Boolean]
    def amazon?
      @cert.subject.to_a.flatten.include? 'echo-api.amazon.com'
    end

    # Check if given signature matches given request
    #
    # @return [Boolean]
    def verified?
      sign = decode_signature
      pkey = public_key
      pkey.verify(hash, sign, @request)
    end

    # Decode base64-encoded signature
    #
    # @return [String] decoded signature
    def decode_signature
      Base64.decode64(@signature)
    end

    # Get public key from certificate
    #
    # @return [OpenSSL::PKey::RSA] OpenSSL PKey object
    def public_key
      @cert.public_key
    end

    # Get hash type for comparison
    #
    # @return [OpenSSL::Digest::SHA1] OpenSSL SHA1 hash
    def hash
      OpenSSL::Digest::SHA1.new
    end
  end
end
