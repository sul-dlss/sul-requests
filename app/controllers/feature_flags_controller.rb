# frozen_string_literal: true

# :nodoc:
class FeatureFlagsController < ApplicationController
  def index
    authorize! :toggle, :feature_flags
  end

  def update
    authorize! :toggle, :feature_flags
    cookies[:feature_flags] = Array(params[:feature_flags]).join(',')

    redirect_back_or_to(root_path)
  end

  def rescue_can_can(*)
    redirect_to login_by_sunetid_path(referrer: request.original_url) and return unless sso_user?

    super
  end
end
