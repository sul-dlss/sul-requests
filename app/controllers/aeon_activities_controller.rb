# frozen_string_literal: true

###
#  Controller for displaying Aeon activites for a user
###
class AeonActivitiesController < ApplicationController
  ALLOWED_SORTS = %w[sort_key name activity_type].freeze
  EXCEL_UTF8_BOM = "\uFEFF"
  include AeonController

  before_action :authorize_activity
  before_action :load_activities, except: :show

  def index; end

  def show
    activity = all_activities.find(params[:id])
    return head :not_found unless activity

    respond_to do |format|
      format.csv do
        send_data(activity_csv(activity), filename: "activity-#{activity.id}-#{activity.name.parameterize}.csv")
      end
    end
  end

  def requests; end

  private

  def activity_csv(activity)
    users = activity.users.index_by(&:username)

    CSV.generate(+EXCEL_UTF8_BOM) do |csv|
      csv << ['Transaction ID', 'Creation date', 'Requester', 'Title', 'Author', 'Call number', 'Box/Volume',
              'Date', 'FOLIO location', 'Item number', 'Item URL']

      activity.requests.sort_by(&:transaction_number).each do |request|
        csv << activity_csv_row(request:, requester: users[request.username])
      end
    end
  end

  def activity_csv_row(request:, requester:)
    [request.transaction_number, request.creation_date.to_date.iso8601, requester&.name,
     request.item_title, request.item_author, request.call_number, request.item_volume,
     request.item_date, request.location, request.item_number, request.item_url]
  end

  def authorize_activity
    authorize! :read, Aeon::Activity
  end

  def load_activities
    @activities = all_activities
    filter
    sort_results
  end

  def filter
    return unless params[:filter]

    @activities = @activities.select { |activity| activity.activity_type == params[:filter] }
  end

  def sort_results
    sort = params[:sort].presence_in(ALLOWED_SORTS) || 'sort_key'
    sort_keys = ([sort] + ALLOWED_SORTS).compact.uniq
    @activities = @activities.sort_by { |obj| sort_keys.map { |k| obj.public_send(k) } }
  end

  def all_activities
    @all_activities ||= current_user.aeon.activities
  end
end
