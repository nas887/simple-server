module AdminAuthentication
  extend ActiveSupport::Concern
  included do
    before_action :authenticate_admin!
    after_action :verify_authorized
    after_action :verify_policy_scoped, only: :index

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def user_not_authorized
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referrer || root_path)
    end
  end
end