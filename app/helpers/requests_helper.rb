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

  def label_for_item_selector_holding(holding)
    if holding.checked_out?
      content_tag :span, class: 'status float-end availability unavailable' do
        "Due #{holding.due_date}"
      end
    else
      content_tag :span, class: "status float-end availability #{holding.status_class}" do
        holding.status_text
      end
    end
  end

  def queue_length_display(item, prefix: nil)
    return '' if item.available?

    item_status = item.checked_out? ? "Checked out - Due #{item.due_date}" : item.status
    wait_list = item.queue_length.zero? ? 'No waitlist' : 'There is a waitlist ahead of your request'
    "#{prefix}#{item_status} | #{wait_list}"
  end

  def requests_patron_item_selector_label(item, not_requestable: false)
    status_class = item.checked_out? || not_requestable ? 'unavailable' : item.status_class
    status_text = if not_requestable
                    item.status_text == 'Not requestable' ? item.status_text : "Not requestable / #{item.status_text}"
                  else
                    item.status_text
                  end
    due_date = item.checked_out? ? content_tag(:span, "Due #{item.due_date}", class: 'ms-1 text-danger') : ''
    content_tag :span, class: "status float-end availability #{status_class}" do
      availability_bootstrap_icon(status_class) + status_text + due_date
    end
  end

  def callnumber_label(item)
    return '(no call number)' if item.callnumber.blank?

    item.callnumber
  end

  # rubocop:disable Metrics/MethodLength
  def availability_bootstrap_icon(css_class)
    case css_class
    when 'available'
      content_tag(:i, '', class: 'bi bi-check align-middle fs-5 text-success')
    when 'available noncirc'
      content_tag(:i, '', class: 'bi bi-check align-middle fs-5 text-warning')
    when 'unavailable'
      content_tag(:i, '', class: 'bi bi-x fs-4 align-middle text-danger')
    when 'deliver-from-offsite noncirc'
      content_tag(:i, '', class: 'bi bi-truck fs-5 align-middle text-warning m-1')
    when 'deliver-from-offsite'
      content_tag(:i, '', class: 'bi bi-truck fs-5 align-middle text-success m-1')
    when 'hold-recall'
      content_tag(:i, '', class: 'bi bi-exclamation-triangle align-middle m-1 fs-5 text-warning')
    else
      ''
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

  # For the reading room information, we need to check if 'ARS' is in the location details
  # for the library. An example is SAL3, which should show the ARS reading room information
  # and so should return ARS as the library code for the reading room text block.
  # This logic will be extended in the future to cover any location that has a pageAeonSite value.
  def aeon_reading_room_code
    # TODO: this supports PatronRequest and Request; refactor to remove support for Request
    code = current_request.try(:origin_location_code) || current_request.try(:origin_location)
    folio_types_location = Folio::Types.locations.find_by(code:) if code
    return current_request.origin_library_code unless folio_types_location

    details = folio_types_location.details
    details.key?('pageAeonSite') && details['pageAeonSite'] == 'ARS' ? 'ARS' : current_request.origin_library_code
  end

  # Get the name of the reading room where Aeon items will be prepared for use.
  # A custom name can be set in the settings for each library; otherwise the
  # default is the library name followed by "Reading Room".
  def aeon_reading_room_name
    library = Settings.libraries[aeon_reading_room_code] || Settings.libraries.default
    library.reading_room_label || "#{library['label']} Reading Room"
  end
end
