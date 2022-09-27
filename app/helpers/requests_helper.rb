# frozen_string_literal: true

###
#  Helper module for requests related markup
###
module RequestsHelper
  include PickupLibrariesHelper

  def render_remote_user_check?
    return false unless Settings.features.remote_ip_check
    return unless current_request && current_user.try(:ip_address)

    current_request.check_remote_ip? && !IpRange.includes?(current_user.ip_address)
  end

  def label_for_comments_field
    t("forms.labels.#{current_request.origin}.item_comment",
      default: current_request.class.human_attribute_name(:item_comment)
     )
  end

  def request_status_for_ad_hoc_item(request, item)
    request.item_status(item)
  end

  def status_text_for_item(item)
    ad_hoc_item_status(item) || status_text_for_errored_item(item) || i18n_status_text(item)
  end

  def i18n_location_title_key
    if (current_location = current_request.holdings.first.try(:current_location).try(:code)).present?
      current_location
    elsif (origin_location = current_request.origin_location).present?
      origin_location
    end
  end

  def i18n_library_title_key
    current_request.origin
  end

  def label_for_item_selector_holding(holding)
    if holding.current_location.try(:code) == 'CHECKEDOUT'
      content_tag :span, class: 'status pull-right availability unavailable' do
        "Due #{holding.due_date}"
      end
    else
      content_tag :span, class: "status pull-right availability #{holding.status.availability_class}" do
        holding.status.status_text
      end
    end
  end

  def request_level_request_status(request = current_request)
    if request.symphony_response.usererr_code
      t("symphony_response.failure.code_#{request.symphony_response.usererr_code}.alert_html")
    elsif request.symphony_response.any_successful? && request.symphony_response.any_error?
      t('symphony_response.mixed_failure_html')
    elsif request.symphony_response.all_errored?
      t('symphony_response.failure.default.alert_html')
    end
  end

  def new_scan_path_for_current_request(request = current_request)
    new_scan_path(
      origin: request.origin,
      item_id: request.item_id,
      origin_location: request.origin_location
    )
  end

  def status_page_url_for_request(request)
    if !request.user.sso_user? && request.is_a?(TokenEncryptable)
      polymorphic_url([:status, request], token: request.encrypted_token)
    else
      polymorphic_url([:status, request])
    end
  end

  def request_approval_status(request = current_request)
    RequestApprovalStatus.new(request: request).to_html
  end

  def aeon_pages_path
    Settings.aeon_ere_url
  end

  private

  def ad_hoc_item_status(item)
    return unless item.is_a?(String)

    t('status_text.unlisted')
  end

  def i18n_status_text(item)
    case
    when item.current_location.try(:code) && item.current_location.code.ends_with?('-LOAN')
      t('status_text.hold')
    when item.home_location.ends_with?('-30')
      t('status_text.paged')
    else
      t('status_text.other')
    end
  end

  def status_text_for_errored_item(item)
    return unless item.request_status.errored?

    item.request_status.symphony_user_error_text || item.request_status.text
  end

  def format_date(date)
    Time.zone.parse(date.to_s).strftime('%Y-%m-%d %I:%M%P')
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
