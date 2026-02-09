# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Rails/I18nLocaleTexts

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  def show
    # Handle both 'value' and 'Value' params for compatibility (Aeon currently accepts Value)
    @ead_url = params[:value] || params[:Value]

    if @ead_url.blank?
      flash[:error] = 'No EAD URL provided'
      redirect_to root_path and return
    end

    begin
      ead_client = EadClient.fetch(@ead_url)
      @ead_fields = ead_client.extract_fields
    rescue StandardError => e
      Rails.logger.error("Error fetching EAD: #{e.message}")
      flash[:error] = "Unable to fetch archives data: #{e.message}"
      redirect_to root_path
    end
  end
end

# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Rails/I18nLocaleTexts
