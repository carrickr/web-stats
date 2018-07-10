# frozen_string_literal: true
require 'faker'

urls = ['http://apple.com',
        'https://apple.com',
        'https://www.apple.com',
        'http://developer.apple.com',
        'http://en.wikipedia.org',
        'http://opensource.org']

referrers = ['http://apple.com',
             'https://apple.com',
             'https://www.apple.com',
             'http://developer.apple.com',
             nil]

# Ensure we have at least one entry for 10 sequential days, including today
# and one entry for each of the url and referrer options.
#
# Given we are generating a million records there are low odds that random
# generation would fail to hit every option, even so we explictly create the
# entries to ensure one of each

# Convenience method for calling out to Faker for a random Time
# @return [Time] a time between today and nine days ago, returned as UTC
def random_time
  Faker::Time.between(9.days.ago, DateTime.now, :all)
end

# Dates
9.days.ago.to_datetime.upto(DateTime.now) { |date| Site.create(url: urls.sample, referrer: referrers.sample, created_at: date.utc)}

# URLs
urls.each { |url| Site.create(url: url, referrer: referrers.sample, created_at: random_time)}

# Referrers
referrers.each { |referrer| Site.create(url: urls.sample, referrer: referrer, created_at: random_time)}

# Populate the database with additional records until we reach 1 million
# rather than doing 1 million times .create we'll just do one insert statement

current_id = Site.last.id

values = (1000000-Site.all.size).times.collect {
  current_id += 1
  site = {id: current_id, url: urls.sample, referrer: referrers.sample, created_at: random_time }
  site.delete(:referrer) if site[:referrer].nil?
  site[:hash] = Digest::MD5.hexdigest(site.to_s)
  ["#{site[:id]}","#{site[:url]}","#{site[:referrer]}","#{site[:created_at]}","#{site[:hash]}"]
}

Site.import(['id', 'url', 'referrer', 'created_at', 'hash'],values)
