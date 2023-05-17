# frozen_string_literal: true

##
# Relatively simple utility class to render the status of a request.
# The status can either be pending, a user error, or return the list of items,
# that have either been requested successfully or have returned with an error.
class RequestApprovalStatus
  include ActionView::Context
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TranslationHelper

  attr_reader :request

  def initialize(request:)
    @request = request
  end

  def to_html
    return content_wrapper { pending_text } if pending?
    return content_wrapper { user_error_text } if request.ils_response.user_error?

    safe_join(item_list_with_status_markup)
  end

  def to_text
    return pending_text if pending?

    # Not putting user errors here because it
    # is handled elswehere in the context of the plain text status
    item_list_with_status.join("\n")
  end

  def item_list_with_status
    request.holdings.map do |item|
      if request.ils_response.success?(item.barcode)
        succcess_text_for_item(item.callnumber)
      else
        error_text_for_item(item)
      end
    end
  end

  def pending?
    request.ils_response.blank?
  end

  private

  def request_class_name
    request.class.to_s.underscore
  end

  def request_origin
    request.origin.underscore
  end

  def pending_text
    text = t(
      :"approval_status.#{request_class_name}.pending",
      default: [:"approval_status.#{request_origin}.pending", :'approval_status.default.pending']
    )
    text << " #{t("approval_status.#{request_origin}.extra_note", default: '')}"
    text
  end

  def item_list_with_status_markup
    request.holdings.map do |item|
      if request.ils_response.success?(item.barcode)
        success_markup_for_item(item.callnumber)
      else
        error_markup_for_item(item)
      end
    end
  end

  def error_markup_for_item(item)
    content_wrapper(css_class: 'approval-error') { error_text_for_item(item) }
  end

  def error_text_for_item(item)
    t(:'approval_status.default.error', callnumber: item.callnumber, error_text: item.request_status.try(:text))
  end

  def success_markup_for_item(item)
    content_wrapper { succcess_text_for_item(item) }
  end

  def succcess_text_for_item(item)
    t(
      :"approval_status.#{request_class_name}.success",
      default: [:"approval_status.#{request_origin}.success", :'approval_status.default.success'],
      item: item
    )
  end

  def user_error_text
    t(
      :"symphony_response.failure.code_#{request.ils_response.usererr_code}.alert_html",
      default: :'symphony_response.failure.default.alert_html'
    )
  end

  def content_wrapper(css_class: nil, &block)
    content_tag('dd', class: css_class) do
      yield block
    end
  end
end
