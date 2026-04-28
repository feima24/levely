class EmbeddingService
  MODEL = "text-embedding-3-small"

  def self.generate(text)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.embeddings(
      parameters: {
        model: MODEL,
        input: text
      }
    )
    response.dig("data", 0, "embedding")
  end
end
