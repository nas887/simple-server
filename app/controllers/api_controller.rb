class APIController < ApplicationController
  include ApiAuthentication

  TIME_WITHOUT_TIMEZONE_FORMAT = '%FT%T.%3NZ'.freeze

  skip_before_action :verify_authenticity_token

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def set_sentry_context
    Raven.user_context(
      id: request.headers['HTTP_X_USER_ID'],
      request_facility_id: request.headers['HTTP_X_FACILITY_ID']
    )
  end
end
