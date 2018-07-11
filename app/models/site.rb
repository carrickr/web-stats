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

  # Gets the top n sites for a given day
  # @param [DateTime] date The date to retrieve the results for
  # @param [Int] limit The number of sites you wish to retrieve, defaults to 10
  # @return [Hash] the sites in the form of {date: {site: visits}}
  #  the hash will always be returned ordered such that the first {site: visits}
  #  is the site with the most visits that day
  def top_sites(date:, limit: 10)
    date_key = date.strftime('%Y-%m-%d')
    result_hash = {  date_key => {} }
    # rubocop:disable Metrics/LineLength
    Site.where(created_at: date.all_day).group_and_count(:url).order(Sequel.desc(:count)).limit(limit).all.each do |site|
      result_hash[date_key][site[:url]] = site[:count]
    end
    # rubocop:enable Metrics/LineLength
    result_hash
  end

  # Gets the top n sites over a date range
  # @param [DateTime] start_date the date to start the range on
  # @param [DateTime] end_date the date to end the range on, defaults to today
  # @param [Int] limit The number of sites you wish to retrieve, defaults to 10
  # @return [Hash] the sites in the form of {date: {site: visits}}
  #  the hash will always have its date keys ordered from the start of the
  #  range to the end of the range
  def top_sites_over_daterange(start_date:, end_date: Date.today, limit: 10)
    return_hash = top_sites(date: start_date, limit: limit)
    return return_hash if start_date.to_date == end_date.to_date

    (start_date + 1.day).to_date.upto(end_date.to_date).each do |date|
      return_hash = add_potential_top_sites(current_results: return_hash,
                                            new_sites: top_sites(date: date,
                                                                 limit: limit),
                                            limit: limit)
    end
    return_hash.sort_by { |key, _value| key }.to_h
  end

  # provides a hash containing all sites and the number of times each site
  # was visited on a given date
  # @param [DateTime] date The date to retrieve the results for
  # @return [Hash] the results in the form of {date: {url: visits}]}
  def formatted_visits(date:)
    date_key = date.strftime('%Y-%m-%d')
    return_hash = { date_key => [] }
    visits(date: date).each do |v|
      return_hash[date_key] << { 'url' => v.values[:url],
                                 'visits' => v.values[:count] }
    end
    return_hash
  end

  # provides a hash containing all sites and the number of times each site
  # was visited for every day on the supplied range
  # @param [DateTime] start_date the date to start the range on
  # @param [DateTime] end_date the date to end the range on, defaults to today
  # @return [Hash] the results in the form of {date: {url: visits}]}
  def visits_over_daterange(start_date:, end_date: Date.today)
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

  def top_sites_over_daterange_with_referrers(start_date:, end_date: Date.today, site_limit: 10, referrer_limit: 5)
    result_hash = {}
    sites = top_sites_over_daterange(start_date: start_date, end_date: end_date, limit: site_limit)
    sites.each_key do |date|
      result_hash[date] = []
      sites[date].each_key do |top_site|
        new_hash = {'url' => top_site, 'visits' => sites[date][top_site]}
        referrers_list = get_referrers(date: date, url: top_site, limit: referrer_limit)
        new_hash['referrers'] = referrers_list unless referrers_list.empty?
        result_hash[date] << new_hash
        #byebug
      end
    end
    result_hash
  end

  def get_referrers(date:, url:, limit: 5)
    date = Date.parse(date) if date.class == String
    referrers = []
    Site.where(created_at: date.all_day, url: url).exclude(referrer: nil).group_and_count(:referrer).order(Sequel.desc(:count)).limit(limit).all.each do |referrer|
      referrers << {'url' => referrer[:referrer], 'visits' => referrer[:count]}
    end
    referrers
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

  # Given a hash of top sites currently found and a new hash of sites, this
  # merges the two hashes and restricts the total number of sites in the hash
  # to the limit
  # @param [Hash] current_results, the current results as returned from
  #  Sites.formatted_visits
  # @param [Hash] new_sites, the current results as returned from
  #  Sites.formatted_visits
  # @param [Int] limit the total number of top sites you wish to return
  # @return [Hash] the results in the form of {date: {url: visits}]}
  def add_potential_top_sites(current_results:, new_sites:, limit: 10)
    # As a future optimization this constant flattening/unflattlening
    # is really unneeded, the results should just stay flat throughout
    # the search process
    current_results.merge!(new_sites)
    unflatten_result_hash(flattened_hash: flatten_result_hash(results: current_results), limit: limit)
  end



  # Takes a flattened hash (one with date and url combined) and creates
  # a nested hash
  # trims the total sum of url keys in the hash down to limit
  def unflatten_result_hash(flattened_hash:, limit:)
    return_hash = {}
    flattened_hash.keys[0..limit - 1].each do |key|
      date = key.split('|').first
      url  = key.split('|').last
      return_hash[date] = {} if return_hash[date].nil?
      return_hash[date][url] = flattened_hash[key]
    end
    return_hash
  end

  # Takes a nested hash and flattens it for an easier sort by
  def flatten_result_hash(results:)
    flatten_hash = {}
    results.each_key do |date|
      results[date].each_key do |site|
        flatten_hash["#{date}|#{site}"] = results[date][site]
      end
    end
    flatten_hash = flatten_hash.sort_by { |_key, value| value }.reverse.to_h
  end
end
