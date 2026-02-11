# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  def index
    @appointments = current_user&.aeon&.appointments
  end
end
