# frozen_string_literal: true

# Used for storing visits to websites
# @attr [String] site the url of the website that was visited
# @attr [String, Nil] referrer the referrer, if applicable, to the site visited
# @attr [Time] created_at the time the site was visited, always in utc
# @attr [String] hash a MD5 hash of all values above, excluding nil, values.
# @since 0.0.1
class Site < Sequel::Model
  def after_save
    generate_hash
  end

  def daily_count(day)
    Site.where(created_at: day.utc.all_day).group(:url).size
  end

  def hash
    self[:hash]
  end

  private

  def generate_hash
    t_hash = { id: id, url: url, referrer: referrer, created_at: created_at }
    t_hash.delete(:referrer) if t_hash[:referrer].nil?
    update(hash: Digest::MD5.hexdigest(t_hash.to_s))
  end
end
