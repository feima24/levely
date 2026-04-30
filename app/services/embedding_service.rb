class EmbeddingService
  MODEL = 'text-embedding-3-small'.freeze

  def self.generate(text)
    client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY', nil))
    response = client.embeddings(
      parameters: {
        model: MODEL,
        input: text
      }
    )
    response.dig('data', 0, 'embedding')
  end
end
