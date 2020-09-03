# frozen_string_literal: true

##
# A helper for CDL
module CdlHelper
  def cdl_viewing_link(hold_record, text = 'Open viewer')
    params = {
      url: "#{Settings.purl.url}/#{hold_record.druid}",
      cdl_hold_record_id: hold_record.key
    }
    link_to(
      text,
      "#{Settings.embed.url}/iframe?#{params.to_query}",
      target: '_blank',
      rel: 'noopener noreferrer'
    )
  end
end
