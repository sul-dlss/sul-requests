# frozen_string_literal: true

###
#  Controller for displaying Aeon activites for a user
###
class AeonActivitiesController < ApplicationController
  include AeonController

  before_action :authorize_activity
  before_action :load_activities

  def index; end

  def requests; end

  private

  def authorize_activity
    authorize! :read, Aeon::Activity
  end

  def load_activities
    @activities = current_user.aeon.activities
  end
end
