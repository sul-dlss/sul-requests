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

  def user_data
    required_user_params = [:email_address, :address, :city, :state_or_province, :zip_code, :country, :first_name]
    optional_user_params = [:phone, :address2]
    required_params = [:email_address, :address, :city, :state_or_province, :zip_code, :country, :first_name]

    params.require(required_params)
    hash_params = params.permit(required_user_params + optional_user_params).to_h

    AeonClient::UserData.with_defaults.with(**hash_params)
  end

  def folio_user_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    patron_info = current_user.patron.user_info['personal']
    address = patron_info['addresses'].present? ? patron_info['addresses'].find { |address| address['primaryAddress'] } : {}
    AeonClient::UserData.with_defaults.with(
      email_address: current_user.email_address,
      sso: current_user.sso_user?,
      first_name: patron_info['firstName'],
      last_name: patron_info['lastName'],
      phone: patron_info['phone'],
      address: address['addressLine1'],
      address2: address['addressLine2'],
      city: address['city'],
      state_or_province: address['region'],
      country: address['countryId'],
      zip_code: address['postalCode']
    )
  end

  def accept_terms
    params.require(:aeon_terms)

    aeon_client.create_user(user_data: folio_user_data) if ActiveModel::Type::Boolean.new.cast(params[:aeon_terms])

    redirect_back_or_to(params[:referer])
  end
end
