require 'rails_helper'

RSpec.describe ResultsController, type: :controller do

  describe "GET #top_urls" do
    it "returns http success" do
      get :top_urls
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #top_referrers" do
    it "returns http success" do
      get :top_referrers
      expect(response).to have_http_status(:success)
    end
  end

end
