require 'rails_helper'

RSpec.describe EmbeddingService do
  describe '.generate' do
    it 'Cohereのembed APIから埋め込みベクトルを取得する' do
      stub_request(:post, 'https://api.cohere.com/v2/embed')
        .with(body: hash_including('model' => 'embed-multilingual-v3.0', 'texts' => ['テスト']))
        .to_return(
          status: 200,
          body: { embeddings: { float: [[0.1, 0.2, 0.3]] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = described_class.generate('テスト', input_type: 'search_query')

      expect(result).to eq [0.1, 0.2, 0.3]
    end

    it 'input_typeを省略した場合はsearch_documentとして呼び出す' do
      stub_request(:post, 'https://api.cohere.com/v2/embed')
        .to_return(status: 200, body: { embeddings: { float: [[0.0]] } }.to_json)

      described_class.generate('テスト')

      expect(WebMock).to have_requested(:post, 'https://api.cohere.com/v2/embed')
        .with(body: hash_including('input_type' => 'search_document'))
    end

    it 'APIがエラーを返した場合はnilを返す' do
      stub_request(:post, 'https://api.cohere.com/v2/embed')
        .to_return(status: 401, body: { message: 'invalid api key' }.to_json)

      expect(described_class.generate('テスト')).to be_nil
    end
  end
end
