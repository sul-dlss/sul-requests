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
    case
    when item.is_a?(String) # ad-hoc-item
      t('status_text.unlisted')
    when item.current_location.try(:code) && item.current_location.code.ends_with?('-LOAN')
      t('status_text.hold')
    when item.home_location.ends_with?('-30')
      t('status_text.paged')
    else
      t('status_text.other')
    end
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

  def holding_request_status(holding)
    text = case holding.request_status.msgcode
           when 'P001B', 'P002B'
             'delivery may be delayed'
           end

    content_tag(:span, " (#{text})", class: 'alert-danger small') if text.present?
  end

  private

  def format_date(date)
    Time.zone.parse(date.to_s).strftime('%Y-%m-%d %I:%M%P')
  end

  def searchworks_link(item_id, item_title)
    link_to item_title, "#{Settings.searchworks_link}/#{item_id}"
  end

  def requester_info(user)
    return unless user

    if user.webauth_user?
      mail_to user.to_email_string
    elsif user.email.present?
      mail_to user.email, user.to_email_string
    end
  end
end
