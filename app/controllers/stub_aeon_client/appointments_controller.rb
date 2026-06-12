# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class AppointmentsController < StubAeonClient::ApplicationController
    def index
      render json: StubAeonClient::Appointment.all.select { |x| x.username == params[:username] }
    end

    def create
      appointment = StubAeonClient::Appointment.new(appointment_params.to_h)
      appointment.save!

      render json: appointment, status: :created
    end

    def update # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      appointment = StubAeonClient::Appointment.find(params[:id])
      json_params = JSON.parse(request.raw_post)

      json_params.each do |op|
        case op['op']
        when 'replace'
          appointment.data[op['path'].delete_prefix('/')] = op['value']
        when 'remove'
          appointment.data[op['path'].delete_prefix('/')] = nil
        end
      end
      appointment.save!

      render json: appointment
    end

    def destroy
      appointment = StubAeonClient::Appointment.find(params[:id])
      appointment.destroy!

      head :no_content
    end

    def appointment_params
      params.permit(:username, :readingRoomID, :startTime, :stopTime, :name, :availableToProxies, :appointmentStatus)
    end
  end
end
