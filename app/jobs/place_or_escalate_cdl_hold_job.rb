# frozen_string_literal: true

## PlaceOrEscalateCdlHoldJob
class PlaceOrEscalateCdlHoldJob < ApplicationJob
  def perform(hold_key)
    hold_record = HoldRecord.find(hold_key)
    pseudo_patron = Patron.find_by(library_id: Settings.cdl.pseudo_patron_id)
    pseudo_patron_hold = CatalogInfo.find(hold_record.barcode).hold_records.find do |hold|
      hold.patron_key == pseudo_patron.key
    end

    if pseudo_patron_hold
      symphony_client.update_hold(pseudo_patron_hold.key, recallStatus: 'STANDARD')
    else
      Honeybadger.notify("Hi there, no pseudo patron hold existed for #{pseudo_patron_hold.key}")
    end
  end

  def symphony_client
    @symphony_client ||= SymphonyClient.instance
  end
end
