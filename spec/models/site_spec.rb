# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe Site, type: :model do
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
end
# rubocop:enable Metrics/BlockLength
