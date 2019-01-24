module ApiAuthentication
  extend ActiveSupport::Concern
  included do
    before_action :authenticate
    before_action :validate_facility
    before_action :validate_current_facility_belongs_to_users_facility_group

    def current_user
      @current_user ||= User.find_by(id: request.headers['HTTP_X_USER_ID'])
    end

    def current_facility
      @current_facility ||= Facility.find_by(id: request.headers['HTTP_X_FACILITY_ID'])
    end

    def current_facility_group
      current_user.facility.facility_group
    end

    def validate_facility
      return head :bad_request unless current_facility.present?
    end

    def validate_current_facility_belongs_to_users_facility_group
      return head :unauthorized unless current_user.present? && current_facility_group.facilities.where(id: current_facility.id).present?
    end

    def authenticate
      return head :unauthorized unless authenticated?
      current_user.mark_as_logged_in if current_user.has_never_logged_in?
    end

    def authenticated?
      current_user.present? && current_user.access_token_valid? && access_token_authorized?
    end

    def access_token_authorized?
      authenticate_or_request_with_http_token do |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(token, current_user.access_token)
      end
    end
  end
end