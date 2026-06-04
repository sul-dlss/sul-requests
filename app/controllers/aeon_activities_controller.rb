# frozen_string_literal: true

###
#  Controller for displaying Aeon activites for a user
###
class AeonActivitiesController < ApplicationController
  ALLOWED_SORTS = %w[sort_key name activity_type].freeze
  include AeonController

  before_action :authorize_activity

  def index; end

  def active
    @activities = all_activities.select(&:active?)
    @activity_types = @activities.map(&:activity_type)
    filter
    sort_results
  end

  def past
    @activities = all_activities.reject(&:active?)
    @activity_types = @activities.map(&:activity_type)
    filter
    sort_results
  end

  private

  def authorize_activity
    authorize! :read, Aeon::Activity
  end

  def filter
    return unless params[:filter]

    @activities = @activities.filter { |activity| activity.activity_type == params[:filter] }
  end

  def sort_results
    sort = params[:sort].presence_in(ALLOWED_SORTS) || 'sort_key'
    sort_keys = ([sort] + ALLOWED_SORTS).compact.uniq
    @activities = @activities.sort_by { |obj| sort_keys.map { |k| obj.public_send(k) } }
  end

  def all_activities
    @all_activities ||= current_user.aeon.activities_with_requests
  end
end
