# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class RequestsController < StubAeonClient::ApplicationController
    def index
      render json: StubAeonClient::Request.all.select { |x| x.username == params[:username] }
    end

    def create
      aeon_request = StubAeonClient::Request.new(request_params)
      aeon_request.save!

      render json: aeon_request, status: :created
    end

    def route
      aeon_request = StubAeonClient::Request.find(params[:id])
      aeon_request.transactionStatus = StubAeonClient::Queue.all.find { |x| x.queueName == params[:newStatus] }.id
      aeon_request.transactionDate = Time.zone.now
      aeon_request.save!

      render json: aeon_request
    end

    def update # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      aeon_request = StubAeonClient::Request.find(params[:id])
      json_params = JSON.parse(request.raw_post)

      json_params.each do |op|
        case op['op']
        when 'replace'
          aeon_request.data[op['path'].delete_prefix('/')] = op['value']
        when 'remove'
          aeon_request.data[op['path'].delete_prefix('/')] = nil
        end
      end
      aeon_request.save!

      render json: aeon_request
    end

    def request_params # rubocop:disable Metrics/MethodLength
      params.permit(:requestFor,
                    :appointmentID,
                    :bundleID,
                    :callNumber,
                    :documentType,
                    :eadNumber,
                    :format,
                    :forPublication,
                    :itemAuthor,
                    :itemCitation,
                    :itemDate,
                    :itemEdition,
                    :itemInfo1,
                    :itemInfo2,
                    :itemInfo3,
                    :itemInfo4,
                    :itemInfo5,
                    :itemIssue,
                    :itemISxN,
                    :itemNumber,
                    :itemPages,
                    :itemPlace,
                    :itemPublisher,
                    :itemSubTitle,
                    :itemTitle,
                    :itemVolume,
                    :location,
                    :maxCost,
                    :pageCount,
                    :referenceNumber,
                    :reshelvingLocation,
                    :scheduledDate,
                    :serviceLevel,
                    :shippingOption,
                    :site,
                    :specialRequest,
                    :subLocation,
                    :systemID,
                    :webRequestForm,
                    :username,
                    :appointment,
                    :creationDate,
                    :photoduplicationStatus,
                    :photoduplicationDate,
                    :transactionStatus,
                    :transactionDate,
                    :user,
                    :additionalProp1,
                    :additionalProp2,
                    :additionalProp3)
    end
  end
end
