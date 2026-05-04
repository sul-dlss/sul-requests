# frozen_string_literal: true

###
#  Controller for displaying Aeon activites for a user
###
class AeonActivitiesController < ApplicationController
  include AeonController

  def index
    @activities = current_user.aeon.activities_with_requests.select(&:active?)
  end
end
