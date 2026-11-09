require 'rails_helper'

RSpec.describe 'SemanticSearch', type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', confirmed_at: Time.current) }

  before { sign_in user }

  describe 'POST /semantic_search' do
    context '未ログインの場合' do
      before { sign_out user }

      it 'ログイン画面にリダイレクトされる' do
        post '/semantic_search', params: { query: 'テスト検索' }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'クエリが短すぎる場合' do
      it '422でエラーメッセージが返る' do
        post '/semantic_search', params: { query: 'a' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to eq '検索キーワードを2文字以上入力してください'
      end
    end

    context '検索結果がある場合' do
      let!(:category) { Category.create!(user: user, name: '英語') }
      let!(:daily_log) { DailyLog.create!(user: user, date: Date.current, insights: '気づき') }
      let!(:learning_item) do
        LearningItem.create!(daily_log: daily_log, category: category, summary: '英単語を学習した')
      end
      let!(:embedding) do
        DailyLogEmbedding.create!(daily_log: daily_log, embedding_model: 'embed-multilingual-v3.0',
                                  embedding: Array.new(1024, 0.1))
      end

      before do
        stub_request(:post, 'https://api.cohere.com/v2/embed')
          .to_return(status: 200, body: { embeddings: { float: [Array.new(1024, 0.1)] } }.to_json)
        stub_request(:post, 'https://api.cohere.com/v2/chat')
          .to_return(status: 200, body: { message: { content: [{ text: '要約' }] } }.to_json)
      end

      it '200になり、結果と要約が返る' do
        post '/semantic_search', params: { query: '英単語について' }

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['summary']).to eq '要約'
        expect(body['results'].first['items'].first['body']).to eq '英単語を学習した'
      end
    end

    context 'Cohereの埋め込みAPIがエラーを返した場合' do
      before do
        stub_request(:post, 'https://api.cohere.com/v2/embed').to_return(status: 500, body: 'error')
      end

      it '500になり、エラーメッセージが返る' do
        post '/semantic_search', params: { query: '英単語について' }

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body['error']).to eq 'エラーが発生しました'
      end
    end
  end
end
