# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::SitesController, type: :controller do
  before(:all) do
    Site.create(url: 'http://apple.com', created_at: Date.today)
  end
  describe 'GET top_urls_api_v1_sites' do
    it 'returns json in the body' do
      get :top_urls, {format: :json}
      expect(JSON.parse(response.body)).to be_truthy
    end
  end

  describe 'GET top_referrers_api_v1_sites' do
    it 'returns json in the body' do
      get :top_urls, {format: :json}
      expect(JSON.parse(response.body)).to be_truthy
    end
  end

end
