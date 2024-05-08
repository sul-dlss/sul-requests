# frozen_string_literal: true

###
#  ItemStatus class to handle the status data and approval for each barcoded item
###
class ItemStatus
  attr_reader :id, :request

  def initialize(request, id)
    @request = request
    @id = id
    @request.request_status_data ||= {}
  end

  def as_json(*)
    {
      id: @id,
      approved: approved?,
      approver:,
      approval_time: localized_approval_time,
      msgcode:,
      text: user_error_text || text,
      usererr_code: user_error_code,
      errored: errored?
    }
  end

  def msgcode
    ils_status[:msgcode]
  end

  def text
    ils_status[:text]
  end

  def user_error_text
    @request&.ils_response&.usererr_text.presence
  end

  def user_error_code
    @request&.ils_response&.usererr_code.presence
  end

  def errored?
    user_error_code.present? || !ils_item_successful?
  end

  def approved?
    status_object[:approved]
  end

  def approver
    status_object[:approver]
  end

  def approval_time
    status_object[:approval_time]
  end

  def approve!(user, approval_time = nil)
    self.status_object = {
      approved: true,
      approval_time: (approval_time || Time.zone.now).to_s,
      approver: user
    }.with_indifferent_access
    @request.approval_status = :approved if @request.all_approved?
    @request.save!
  end

  private

  def ils_item_successful?
    return true if non_existent_item_in_ils_response_for_mediated_page?

    @request.ils_response.success?(@id)
  end

  def non_existent_item_in_ils_response_for_mediated_page?
    # This makes sure medidated pages that have not been touched not reported as errors
    @request.is_a?(MediatedPage) && @request.ils_response.items_by_barcode[@id].blank?
  end

  def localized_approval_time
    return nil unless approval_time.present?

    I18n.l(Time.zone.parse(approval_time), format: :short)
  end

  def status_object
    @request.request_status_data[@id] || default_status_object
  end

  def status_object=(value = {})
    @request.request_status_data[@id] = value
  end

  def ils_status
    return {} unless @request.ils_response

    (@request.ils_response.items_by_barcode[@id] || {}).with_indifferent_access
  end

  def reload_request
    return unless @request.persisted?

    @request.reload
    @request.request_status_data ||= {}
  end

  def default_status_object
    {
      approved: false,
      approver: nil,
      approval_time: nil
    }.with_indifferent_access
  end
end
