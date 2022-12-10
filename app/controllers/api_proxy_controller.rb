require 'net/http'
require 'uri'

# This is used for testing only
#
class APIProxyController < ApplicationController
  def default
    uri = "/#{params[:url]}"
    uri += ".#{params[:format]}" if params[:format]

    parameters =
      params.permit!.to_h.except('controller', 'action', 'url', 'format')

    response = if request.get?
      NastyProxy.get uri
    elsif request.post?
      NastyProxy.post uri, body: parameters
    elsif request.put?
      NastyProxy.put uri, body: parameters
    end

    render json: response
  end
end
