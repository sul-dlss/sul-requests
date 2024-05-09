# frozen_string_literal: true

###
#  Helper module for requests related markup
###
module RequestsHelper
  include PickupLibrariesHelper

  def status_text_for_item(item)
    status_text_for_errored_item(item) || i18n_status_text(item)
  end

  def queue_length_display(item, prefix: nil, title_only: false)
    return "#{prefix}On order | No waitlist" if title_only

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
    content_tag :span, class: "status availability #{status_class}" do
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

  def request_approval_status(request = current_request)
    RequestApprovalStatus.new(request:).to_html
  end

  def aeon_pages_path(*)
    Settings.aeon_ere_url
  end

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

  private

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
