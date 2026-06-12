# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class UsersController < StubAeonClient::ApplicationController
    def index
      render json: StubAeonClient::User.all
    end

    def show
      @user = StubAeonClient::User.all.find { |x| x.username == params[:username] }

      if @user.nil?
        render json: { error: 'User not found' }, status: :not_found
        return
      end

      render json: @user
    end

    def create
      @user = StubAeonClient::User.new(**create_params)

      if @user.save
        render json: @user, status: :created
      else
        render json: @user.errors, status: :unprocessable_content
      end
    end

    def create_params # rubocop:disable Metrics/MethodLength
      params.permit(:lastName,
                    :firstName,
                    :dateOfBirth,
                    :id,
                    :idType,
                    :altID,
                    :altIDType,
                    :status,
                    :department,
                    :organization,
                    :eMailAddress,
                    :phone,
                    :fax,
                    :authType,
                    :registrationStatus,
                    :notificationMethod,
                    :deliveryMethod,
                    :expirationDate,
                    :address,
                    :address2,
                    :city,
                    :state,
                    :zip,
                    :country,
                    :billingCategory,
                    :rssid,
                    :sAddress,
                    :sAddress2,
                    :sCity,
                    :sState,
                    :sZip,
                    :sCountry,
                    :cleared,
                    :requestLimit,
                    :researchTopics,
                    :researchTopicsSharing,
                    :userInfo1,
                    :userInfo2,
                    :userInfo3,
                    :userInfo4,
                    :userInfo5,
                    :preferredName,
                    :username,
                    :lastChangedDate,
                    :imageID,
                    :creationDate,
                    :additionalProp1,
                    :additionalProp2,
                    :additionalProp3)
    end
  end
end
