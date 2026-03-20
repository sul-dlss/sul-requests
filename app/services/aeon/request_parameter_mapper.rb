module Aeon
  class RequestParameterMapper
    def self.to_aeon_options(key)
      attributes.fetch(key.to_sym)
    end

    def self.transform_value(key, our_value)
      options = to_aeon_options(key)

      value = our_value&.truncate(options[:truncate], omission: '…') if options[:truncate]

      value
    end

    def self.cast_value(key, their_value)
      options = to_aeon_options(key)

      value = their_value

      value = options[:class].from_dynamic(value) if options[:class].respond_to?(:from_dynamic) && value
      value = value.presence if value.is_a?(String)

      value
    end

    def self.attributes
      @attributes ||= {}
    end

    def self.attribute(our_key, their_key, **options)
      attributes[our_key] = options.merge(key: their_key)
    end

    attribute :appointment, 'appointment', class: Aeon::Appointment
    attribute :appointment_id, 'appointmentID'
    attribute :call_number, 'callNumber', truncate: 255
    attribute :creation_date, 'creationDate'
    attribute :document_type, 'documentType'
    attribute :ead_number, 'eadNumber', truncate: 255
    attribute :for_publication, 'forPublication'
    attribute :format, 'format', truncate: 255
    attribute :item_author, 'itemAuthor', truncate: 255
    attribute :item_citation, 'itemCitation', truncate: 255
    attribute :item_date, 'itemDate', truncate: 50
    attribute :item_info1, 'itemInfo1', truncate: 255
    attribute :item_info2, 'itemInfo2', truncate: 255
    attribute :item_info3, 'itemInfo3', truncate: 255
    attribute :item_info4, 'itemInfo4', truncate: 255
    attribute :item_info5, 'itemInfo5', truncate: 255
    attribute :item_number, 'itemNumber', truncate: 50
    attribute :item_subtitle, 'itemSubTitle', truncate: 255
    attribute :item_title, 'itemTitle', truncate: 255
    attribute :item_volume, 'itemVolume', truncate: 255
    attribute :location, 'location', truncate: 255
    attribute :photoduplication_date, 'photoduplicationDate'
    attribute :photoduplication_status, 'photoduplicationStatus'
    attribute :reference_number, 'referenceNumber', truncate: 50
    attribute :shipping_option, 'shippingOption', truncate: 255
    attribute :site, 'site'
    attribute :special_request, 'specialRequest', truncate: 255
    attribute :system_id, 'system_id'
    attribute :transaction_date, 'transactionDate'
    attribute :transaction_number, 'transactionNumber'
    attribute :transaction_status, 'transactionStatus'
    attribute :username, 'username', truncate: 50
    attribute :web_request_form, 'webRequestForm', truncate: 100, default: 'SUL Requests'
  end
end
