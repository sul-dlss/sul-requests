# frozen_string_literal: true

###
#  Controller for displaying Aeon activites for a user
###
class AeonActivitiesController < ApplicationController
  ALLOWED_SORTS = %w[sort_key name activity_type].freeze
  include AeonController

  before_action :authorize_activity
  before_action :activities

  def index; end

  def requests; end

  private

  def authorize_activity
    authorize! :read, Aeon::Activity
  end

  def activities
    @activities ||= current_user.aeon.activities
  end
end
