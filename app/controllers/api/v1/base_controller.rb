# Base controller for version 1 of our api
class Api::V1::BaseController < ApplicationController
  respond_to :json
end
