require 'net/http'
require 'json'

class EmbeddingService
  MODEL = 'embed-multilingual-v3.0'.freeze

  def self.generate(text, input_type: 'search_document')
    uri = URI('https://api.cohere.com/v2/embed')

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{ENV.fetch('COHERE_API_KEY', nil)}"
    request['Content-Type'] = 'application/json'
    request.body = {
      texts: [text],
      model: MODEL,
      input_type: input_type,
      embedding_types: ['float']
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    result.dig('embeddings', 'float', 0)
  end
end
