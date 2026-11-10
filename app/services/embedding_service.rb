require 'net/http'
require 'json'

class EmbeddingService
  MODEL = 'embed-multilingual-v3.0'.freeze
  API_URL = 'https://api.cohere.com/v2/embed'.freeze

  def self.generate(text, input_type: 'search_document')
    response = post_request(build_body(text, input_type))
    JSON.parse(response.body).dig('embeddings', 'float', 0)
  end

  def self.build_body(text, input_type)
    { texts: [text], model: MODEL, input_type: input_type, embedding_types: ['float'] }.to_json
  end

  def self.post_request(body)
    http = build_http
    request = Net::HTTP::Post.new(API_URL)
    request['Authorization'] = "Bearer #{ENV.fetch('COHERE_API_KEY', nil)}"
    request['Content-Type'] = 'application/json'
    request.body = body
    http.request(request)
  end

  def self.build_http
    uri = URI(API_URL)
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = true
      http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    end
  end

  private_class_method :build_body, :post_request, :build_http
end
