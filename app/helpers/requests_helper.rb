###
#  Helper module for requests related markup
###
module RequestsHelper
  include PickupLibrariesHelper

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
    if !request.symphony_response.success?
      t(
        "symphony_response.failure.code_#{request.symphony_response.usererr_code}.alert_html",
        default: 'symphony_response.failure.default.alert_html'.to_sym
      )
    elsif request.symphony_response.mixed_status?
      t('symphony_response.mixed_failure_html')
    end
  end

  def holding_request_status(holding, request = current_request)
    return if request.symphony_response.success?(holding.barcode)
    return if (text = holding.request_status.try(:text)).blank?
    content_tag(:span, " (#{text})", class: 'alert-danger small')
  end

  def new_scan_path_for_current_request(request = current_request)
    new_scan_path(
      origin: request.origin,
      item_id: request.item_id,
      origin_location: request.origin_location
    )
  end

  def symphony_request_failed_due_to_user_privs?
    SULRequests::Application.config.no_user_privs_codes.include?(
      current_request.symphony_response.usererr_code
    )
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

  def searchworks_link(item_id, item_title)
    link_to item_title, "#{Settings.searchworks_link}/#{item_id}", 'data-behavior': 'truncate'
  end

  def requester_info(user)
    return unless user

    if user.webauth_user? || user.email_address.present?
      mail_to user.email_address, user.to_email_string
    elsif user.library_id_user?
      user.library_id
    end
  end
end
