###
#  ItemStatus class to handle the status data and approval for each barcoded item
###
class ItemStatus
  def initialize(request, id)
    @request = request
    @id = id
    @request.request_status_data ||= {}
  end

  def as_json(*)
    {
      id: @id,
      approved: approved?,
      approver: approver,
      approval_time: localized_approval_time,
      msgcode: msgcode,
      text: symphony_user_error_text || text,
      usererr_code: symphony_user_error_code,
      errored: errored?
    }
  end

  def msgcode
    symphony_status[:msgcode]
  end

  def text
    symphony_status[:text]
  end

  def symphony_user_error_text
    return unless @request.symphony_response && @request.symphony_response.usererr_text.present?
    @request.symphony_response.usererr_text
  end

  def errored?
    !approved? && (symphony_user_error_code.present? || !symphony_item_successful?)
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

  def approve!(user)
    @request.send_to_symphony_now!(barcodes: [@id])
    reload_request # reloading to get any attributes saved to the database above
    return unless symphony_item_successful?
    self.status_object = {
      approved: true,
      approval_time: Time.zone.now.to_s,
      approver: user
    }.with_indifferent_access
    @request.approval_status = :approved if @request.all_approved?
    @request.save!
  end

  private

  def symphony_item_successful?
    return true if (@request.ad_hoc_items || []).include?(@id)
    return true if non_existent_item_in_symphony_response_for_mediated_page?
    @request.symphony_response.success?(@id)
  end

  def non_existent_item_in_symphony_response_for_mediated_page?
    # This makes sure medidated pages that have not been touched not reported as errors
    @request.is_a?(MediatedPage) && @request.symphony_response.items_by_barcode[@id].blank?
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

  def symphony_status
    return {} unless @request.symphony_response

    (@request.symphony_response.items_by_barcode[@id] || {}).with_indifferent_access
  end

  def symphony_user_error_code
    return unless @request.symphony_response && @request.symphony_response.usererr_code.present?
    @request.symphony_response.usererr_code
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
