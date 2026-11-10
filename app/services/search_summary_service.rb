require 'net/http'
require 'json'

class SearchSummaryService
  MODEL = 'command-a-03-2025'.freeze
  API_URL = 'https://api.cohere.com/v2/chat'.freeze

  def self.generate(query, search_results)
    return nil if search_results.blank?

    response = post_request(build_body(query, search_results))
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("SearchSummaryService API error: #{response.code} #{response.body}")
      return nil
    end

    JSON.parse(response.body).dig('message', 'content', 0, 'text')
  rescue StandardError => e
    Rails.logger.error("SearchSummaryService error: #{e.message}")
    nil
  end

  def self.build_body(query, search_results)
    context = search_results.map { |r| format_context(r) }.join("\n\n")
    {
      model: MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: "質問: #{query}\n\n関連する学習記録:\n#{context}" }
      ],
      max_tokens: 500,
      temperature: 0.7
    }.to_json
  end

  def self.system_prompt
    <<~PROMPT.strip
      あなたは学習記録を要約するアシスタントです。
      ユーザーの過去の学習ログを基に、知識を整理して簡潔に回答してください。
      日付や具体的な学習内容に言及し、学習の流れや関連性を示してください。
      回答は日本語で、内容量に応じて適切な長さで回答してください。
    PROMPT
  end

  def self.format_context(result)
    items = result[:items].map { |i| "- [#{i[:category] || '未分類'}] #{i[:body]}" }.join("\n")
    insights = result[:insights] ? "\n気づき: #{result[:insights]}" : ''
    "【#{result[:date]}】\n#{items}#{insights}"
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

  private_class_method :build_body, :system_prompt, :format_context, :post_request, :build_http
end
