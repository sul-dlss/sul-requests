###
#  Helper module for requests related markup
###
module RequestsHelper
  def select_for_pickup_libraries(form)
    pickup_libraries = form.object.library_location.pickup_libraries
    return unless pickup_libraries.present?
    select_for_multiple_libraries(form, pickup_libraries) || single_library_markup(form, pickup_libraries.first)
  end

  def label_for_pickup_libraries_dropdown(pickup_libraries)
    if pickup_libraries.many?
      'Deliver to'
    else
      'Must be used in'
    end
  end

  def label_for_comments_field
    t("forms.labels.#{current_request.origin}.item_comment",
      default: current_request.class.human_attribute_name(:item_comment)
     )
  end

  def request_status_for_ad_hoc_item(request, item)
    SearchworksItem::RequestedHoldings::RequestStatus.new(request, item)
  end

  def status_text_for_item(item)
    case
    when item.is_a?(String) # ad-hoc-item
      t('status_text.unlisted')
    when item.home_location.ends_with?('-30')
      t('status_text.paged')
    when item.current_location.try(:code) && item.current_location.code.ends_with?('-LOAN')
      t('status_text.hold')
    else
      t('status_text.other')
    end
  end

  private

  def select_for_multiple_libraries(form, pickup_libraries)
    return unless pickup_libraries.keys.length > 1
    form.select :destination,
                pickup_libraries_array(pickup_libraries),
                {
                  label: label_for_pickup_libraries_dropdown(pickup_libraries),
                  selected: SULRequests::Application.config.default_pickup_library
                },
                aria: { controls: 'scheduler-text' },
                data: { 'paging-schedule-updater' => 'true' }
  end

  def single_library_markup(form, library)
    <<-HTML
      <div class='form-group'>
        <div class='#{label_column_class} control-label'>
          #{label_for_pickup_libraries_dropdown([])}
        </div>
        <div class='#{content_column_class} input-like-text' data-single-library-value='#{library.first}'>
          #{library.last}
        </div>
        #{form.hidden_field :destination, value: library.first}
      </div>
    HTML
  end

  def pickup_libraries_array(pickup_libraries)
    pickup_libraries.map do |k, v|
      [v, k]
    end
  end

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
