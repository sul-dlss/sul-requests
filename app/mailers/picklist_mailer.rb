# frozen_string_literal: true

###
#  Mailer class to send emails to mediators after requests have been submitted
###
class PicklistMailer < ApplicationMailer
  # Send a picklist email that includes all items approved since the last time the
  # picklist was generated.
  def self.deliver_picklist(
    location,
    last_run_file: nil,
    default: (Time.zone.now - 1.day)...Time.zone.now
  )
    last_run_file ||= Rails.root + "tmp/state/picklist_last_send_#{location}_#{Rails.env}"

    with_last_run_bookkeeping(last_run_file) do |stored_last_run|
      range = stored_last_run.present? ? Time.zone.parse(stored_last_run)...Time.zone.now : default

      picklist_notification(location, range: range).deliver_now

      range.last
    end
  end

  def self.with_last_run_bookkeeping(file)
    File.open(file, File::RDWR | File::CREAT) do |f|
      f.flock(File::LOCK_EX)
      current_value = f.read

      new_value = yield(current_value)

      f.rewind
      f.write(new_value.to_s)
      f.flush
      f.truncate(f.pos)
    end
  end

  def picklist_notification(location, range:)
    @items = approved_items_from(location, range)

    return if @items.empty?

    attachments["picklist-#{range.first.iso8601}.html"] = ApplicationController.render(
      template: 'admin/picklist',
      layout: false,
      assigns: { items: @items, range: range }
    )

    mail(
      to: picklist_notification_email_address(location),
      subject: "#{location} picklist"
    )
  end

  private

  def picklist_notification_email_address(location)
    Rails.application.config.picklist_contact_info.fetch(
      location
    )[:email]
  end

  def approved_items_from(location, range)
    MediatedPage.for_origin(location).where(updated_at: range).flat_map do |request|
      request.item_statuses.select do |item_status|
        item_status.approved? &&
          item_status.approval_time &&
          Time.zone.parse(item_status.approval_time).between?(range.begin, range.end)
      end
    end
  end
end
