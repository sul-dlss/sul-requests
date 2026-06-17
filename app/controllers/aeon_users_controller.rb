# frozen_string_literal: true

###
#  Controller for managing Aeon user information
###
class AeonUsersController < ApplicationController
  include AeonController

  before_action do
    authorize! :create, Aeon::User
  end

  def new; end

  def create
    aeon_client.create_user(user_data:) if ActiveModel::Type::Boolean.new.cast(params[:aeon_terms])
    redirect_back_or_to(params[:referrer])
  end

  def accept_terms
    params.require(:aeon_terms)

    aeon_client.create_user(user_data: folio_user_data) if ActiveModel::Type::Boolean.new.cast(params[:aeon_terms])

    redirect_back_or_to(params[:referer])
  end

  private

  def user_data
    required_user_params = [:email_address, :address, :city, :state_or_province, :zip_code, :country, :first_name]
    optional_user_params = [:phone, :address2]

    params.require(required_user_params)
    hash_params = params.permit(required_user_params + optional_user_params).to_h

    AeonClient::UserData.with_defaults.with(**hash_params)
  end

  def folio_user_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    personal_data = current_user.patron.personal_data
    primary_address = current_user.patron.primary_address
    AeonClient::UserData.with_defaults.with(
      email_address: current_user.email_address,
      sso: current_user.sso_user?,
      first_name: personal_data['firstName'],
      last_name: personal_data['lastName'],
      phone: personal_data['phone'],
      address: primary_address['addressLine1'],
      address2: primary_address['addressLine2'],
      city: primary_address['city'],
      state_or_province: primary_address['region'],
      country: primary_address['countryId'],
      zip_code: primary_address['postalCode']
    )
  end
end
