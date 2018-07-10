# The base controller for supplying API reports in json format

class Api::V1::SitesController < Api::V1::BaseController

  # generates a json output of all sites visited over the past five days,
  # including today.  Output comes in body in the form of:
  # {date: [{url: , visits:}]
  def top_urls
    respond_with Site.new.formatted_visits_over_daterange(start_date: 4.days.ago)
  end

end
