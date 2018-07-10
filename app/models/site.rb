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

  # Queries the database to determine the number of views per url on the given
  # day
  # @param [Date] date the day you wish to retrieve views for
  # @return [Array <Site>] an array of sites with their visits, use
  #   Site.values[:url] and Site.values[:count] for visit information
  def visits(date:)
    Site.where(created_at: date.all_day).group_and_count(:url).all
  end

  # provides a hash containing all sites and the number of times each site
  # was visited on a given date
  # @param [DateTime] date The date to retrieve the results for
  # @return [Hash] a hash in the form of {date: [{url: , visits:}]}
  def formatted_visits(date:)
    date_key = date.strftime("%Y-%m-%d")
    return_hash = { date_key => []}
    visits(date: date).each do |v|
      return_hash[date_key] << {'url' => v.values[:url], 'visits' => v.values[:count]}
    end
    return_hash
  end

  # provides a hash containing all sites and the number of times each site
  # was visited for every day on the supplied range
  # @param [DateTime] start_date the date to start the range on
  # @param [DateTime] end_date the date to end the range on, defaults to today
  # @return [Hash] the results in the form of {date: [{url: , visits:}]}
  def formatted_visits_over_daterange(start_date:,end_date: Date.today)
    return_hash = {}
    start_date.to_date.upto(end_date.to_date).each do |date|
      return_hash.merge!(formatted_visits(date: date))
    end
    return_hash
  end

  # override the default hash method to return MD5 hexdigest stored
  # in the database
  # @return [String] the MD5 hexdigest
  def hash
    self[:hash]
  end

  private

  # used as an after_save hook to generater a MD5 Hexdigest using the
  # :id, :url, :referrer, and :created_at attributes (referrer is excluded if
  # nil).
  # Uses update when writing the hash to avoid triggering the after_save hook
  # and creating a loop
  def generate_hash
    t_hash = { id: id, url: url, referrer: referrer, created_at: created_at }
    t_hash.delete(:referrer) if t_hash[:referrer].nil?
    update(hash: Digest::MD5.hexdigest(t_hash.to_s))
  end
end
