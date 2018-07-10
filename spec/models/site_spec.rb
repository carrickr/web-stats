# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/LineLength
RSpec.describe Site, type: :model do
  let(:subject) { described_class.new }
  before(:each) { DatabaseCleaner.clean }

  describe 'the MD5 Digest' do
    let!(:fixed_timestamp) { Time.now }
    let!(:site_with_referrer) do
      described_class.create(url: 'http://apple.com',
                             referrer: 'http://developer.apple.com',
                             created_at: fixed_timestamp)
    end
    let!(:site_nil_referrer) do
      described_class.create(url: 'http://apple.com',
                             referrer: nil,
                             created_at: fixed_timestamp)
    end

    describe '.hash' do
      it 'overrides the default hash method and returns a string' do
        expect(site_with_referrer.hash.class).to eq(String)
      end
    end

    describe '.generate_hash' do
      it 'includes a non-nil referrer when generating the hash' do
        expect(site_with_referrer.hash).to eq(Digest::MD5.hexdigest({ id: site_with_referrer.id,
                                                                      url: 'http://apple.com',
                                                                      referrer: 'http://developer.apple.com',
                                                                      created_at: fixed_timestamp }.to_s))
      end

      it 'does not include a nil referrer when generating the hash' do
        expect(site_nil_referrer.hash).to eq(Digest::MD5.hexdigest({ id: site_nil_referrer.id,
                                                                     url: 'http://apple.com',
                                                                     created_at: fixed_timestamp }.to_s))
      end
    end
  end

  describe '.visits' do
    let!(:first_site_visited_today) do
      described_class.create(url: 'http://apple.com',
                             created_at: Date.today)
    end
    let!(:second_site_visited_today) do
      described_class.create(url: 'http://en.wikipedia.org',
                             created_at: Date.today)
    end
    let!(:site_visited_1_day_ago) do
      described_class.create(url: 'http://developer.apple.com',
                             created_at: 1.days.ago)
    end

    it 'gets all sites visited on a specific day' do
      expect(subject.visits(date: Date.today).size).to eq(2)
    end

    it 'returns the url of each visited site' do
      result = subject.visits(date: Date.today)
      expect([result[0].values[:url], result[1].values[:url]]).to contain_exactly('http://apple.com', 'http://en.wikipedia.org')
    end

    it 'returns the count of visits for each site' do
      # visit each again so that our counts are different than the counts from
      # site_visited_1_day_ago, so if somehow that one ever creeps into
      # the test will get a count of 1 rather than 2 and fail
      described_class.create(url: 'http://apple.com', created_at: Time.now)
      described_class.create(url: 'http://en.wikipedia.org', created_at: Time.now)
      result = subject.visits(date: Date.today)
      expect([result[0].values[:count], result[1].values[:count]]).to contain_exactly(2, 2)
    end
  end

  describe 'providing json reports of visits' do
    let!(:first_site_visited_today) do
      described_class.create(url: 'http://apple.com',
                             created_at: Date.today)
    end
    let!(:site_visited_1_day_ago) do
      described_class.create(url: 'http://en.wikipedia.org',
                             created_at: Date.today)
    end
    let!(:site_visited_2_days_ago) do
      described_class.create(url: 'http://developer.apple.com',
                             created_at: 2.days.ago)
    end

    describe '.formatted_visits' do
      it 'returns a hash' do
        expect(subject.formatted_visits(date: Date.today).class).to eq(Hash)
      end

      it 'uses date as the hash key' do
        expect(subject.formatted_visits(date: Date.today).keys).to contain_exactly(Date.today.strftime('%Y-%m-%d'))
      end

      it 'returns the url and visits for a site' do
        expect(subject.formatted_visits(date: Date.today)[Date.today.strftime('%Y-%m-%d')].first).to include('url' => 'http://apple.com', 'visits' => 1)
      end
    end

    describe '.visits_over_daterange' do
      it 'returns a hash' do
        expect(subject.visits_over_daterange(start_date: Date.today).class).to eq(Hash)
      end

      it 'uses date as the hash key' do
        expect(subject.visits_over_daterange(start_date: Date.today).keys).to contain_exactly(Date.today.strftime('%Y-%m-%d'))
      end

      it 'defaults to using Date.today as the end_date' do
        expect(subject.visits_over_daterange(start_date: Date.today).keys).to contain_exactly(Date.today.strftime('%Y-%m-%d'))
      end

      it 'gets a range of dates' do
        expect(subject.visits_over_daterange(start_date: 3.days.ago, end_date: 1.days.ago).keys.size).to eq(3)
      end
    end
  end
  describe 'providing reports of top n websites and their referrers' do
    # Visit one site twice
    let!(:first_visit) { described_class.create(url: 'http://apple.com', created_at: Time.now) }
    let!(:second_visit) { described_class.create(url: 'http://apple.com', created_at: Time.now) }
    # Visit another site once
    let!(:different_site) { described_class.create(url: 'http://developer.apple.com', created_at: Time.now) }

    let(:date_key) { 0.days.ago.strftime('%Y-%m-%d') }
    describe '.top_sites' do
      it 'gets the sites visited' do
        expect(subject.top_sites(date: 0.days.ago)).to include(date_key => { 'http://apple.com' => 2, 'http://developer.apple.com' => 1 })
      end

      it 'returns only the desired number of sites' do
        expect(subject.top_sites(date: 0.days.ago, limit: 1)).to include(date_key => { 'http://apple.com' => 2 })
      end
    end
    describe '.top_sites_over_daterange' do
      let!(:visited_yesterday) { described_class.create(url: 'http://opensource.org', created_at: 1.day.ago) }
      let(:yesterday_date_key) { 1.days.ago.strftime('%Y-%m-%d') }
      it 'gets the sites visited' do
        expect(subject.top_sites_over_daterange(start_date: 0.days.ago)).to include(date_key => { 'http://apple.com' => 2, 'http://developer.apple.com' => 1 })
      end

      it 'gets the sites visited over multiple days' do
        expect(subject.top_sites_over_daterange(start_date: 1.days.ago)).to include(yesterday_date_key => { 'http://opensource.org' => 1 }, date_key => { 'http://apple.com' => 2, 'http://developer.apple.com' => 1 })
      end

      it 'applies limits to the number of results' do
        expect(subject.top_sites_over_daterange(start_date: 1.days.ago, limit: 1)).to include(date_key => { 'http://apple.com' => 2 })
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/LineLength
