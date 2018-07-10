# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
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
      expect([result[0].values[:url], result[1].values[:url]]).to
      contain_exactly('http://apple.com', 'http://en.wikipedia.org')
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
end
# rubocop:enable Metrics/BlockLength
