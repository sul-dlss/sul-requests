# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  helper_method :type_param

  def index
    authorize! :read, Aeon::Request

    @aeon_requests = (current_user&.aeon&.requests || []).select do |request|
      case type_param
      when 'submitted'
        !request.draft?
      when 'draft'
        request.draft?
      end
    end
  end

  def type_param
    (params[:type] || 'submitted').tap do |type|
      raise ActionController::RoutingError, "Invalid type parameter: #{params[:type]}" unless %w[submitted draft].include?(type)
    end
  end
end
