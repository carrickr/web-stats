# frozen_string_literal: true

Rails.application.routes.draw do

  get 'results/top_referrers'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  Rails.application.routes.draw do

  get '/top_urls', to: 'results#top_urls'
  get 'results/top_referrers'

    namespace :api do
      namespace :v1 do
        resource :sites do
          get 'top_urls', to: 'sites#top_urls'
          get 'top_referrers', to: 'sites#top_referrers'
        end
      end
    end
  end
end
