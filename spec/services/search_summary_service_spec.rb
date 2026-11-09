require 'rails_helper'

RSpec.describe SearchSummaryService do
  describe '.generate' do
    let(:search_results) do
      [{ date: '2026-11-01', items: [{ body: '英単語を50個学習した', category: '英語' }], insights: '復習が効果的だった' }]
    end

    it '検索結果が空の場合はAPIを呼ばずにnilを返す' do
      expect(described_class.generate('質問', [])).to be_nil
      expect(WebMock).not_to have_requested(:post, 'https://api.cohere.com/v2/chat')
    end

    it 'Cohereのchat APIから要約を取得する' do
      stub_request(:post, 'https://api.cohere.com/v2/chat')
        .to_return(
          status: 200,
          body: { message: { content: [{ text: '要約結果' }] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = described_class.generate('質問', search_results)

      expect(result).to eq '要約結果'
    end

    it 'APIがエラーを返した場合はnilを返しログに記録する' do
      stub_request(:post, 'https://api.cohere.com/v2/chat')
        .to_return(status: 500, body: 'internal error')

      expect(Rails.logger).to receive(:error).with(/SearchSummaryService API error/)

      expect(described_class.generate('質問', search_results)).to be_nil
    end

    it '通信エラーが発生した場合はnilを返しログに記録する' do
      stub_request(:post, 'https://api.cohere.com/v2/chat').to_timeout

      expect(Rails.logger).to receive(:error).with(/SearchSummaryService error/)

      expect(described_class.generate('質問', search_results)).to be_nil
    end
  end
end
