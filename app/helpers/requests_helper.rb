# frozen_string_literal: true

###
#  Helper module for requests related markup
###
module RequestsHelper
  include PickupLibrariesHelper

  def status_text_for_item(item)
    status_text_for_errored_item(item) || i18n_status_text(item)
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  def i18n_location_title_key
    holding = current_request.holdings.first
    if holding
      if holding.checked_out?
        'CHECKEDOUT'
      elsif holding.on_order?
        'ON-ORDER'
      elsif holding.missing?
        'MISSING'
      elsif holding.processing?
        'INPROCESS'
      else
        current_request.origin_location.presence
      end
    elsif (origin_location = current_request.origin_location).present?
      origin_location
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def i18n_library_title_key
    current_request.origin
  end

  # rubocop:disable Metrics/MethodLength
  def label_for_item_selector_holding(holding)
    if holding.checked_out?
      if Settings.ils.bib_model == 'SearchworksItem'
        content_tag :span, class: 'status pull-right availability unavailable' do
          "Due #{holding.due_date}"
        end
      else
        tag.span class: 'status pull-right availability unavailable' do
          # This content is lazily loaded, because the query to get due_date makes the initial query for items take a long time.
          turbo_frame_tag "due_date_#{holding.id}", src: due_date_path(holding.id)
        end
      end
    else
      content_tag :span, class: "status pull-right availability #{holding.status_class}" do
        holding.status_text
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def request_level_request_status(request = current_request)
    if request.ils_response.usererr_code
      t("symphony_response.failure.code_#{request.ils_response.usererr_code}.alert_html")
    elsif request.ils_response.any_successful? && request.ils_response.any_error?
      t('symphony_response.mixed_failure_html')
    elsif request.ils_response.all_errored?
      t('symphony_response.failure.default.alert_html')
    end
  end

  def request_approval_status(request = current_request)
    RequestApprovalStatus.new(request:).to_html
  end

  def aeon_pages_path(*)
    Settings.aeon_ere_url
  end

  private

  def i18n_status_text(item)
    case
    when item.hold?
      t('status_text.hold')
    when item.paged?
      t('status_text.paged')
    else
      t('status_text.other')
    end
  end

  def status_text_for_errored_item(item)
    return unless item.request_status.errored?

    item.request_status.user_error_text || item.request_status.text
  end

  def searchworks_link(item_id, item_title, html_options = {})
    link_to item_title, "#{Settings.searchworks_link}/#{item_id}", html_options
  end

  def requester_info(user)
    return unless user

    if user.sso_user? || user.email_address.present?
      mail_to user.email_address, user.to_email_string
    elsif user.library_id_user?
      user.library_id
    end
  end
end
