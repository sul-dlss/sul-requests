# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class Request < AeonRecord
    store :data, accessors: [:requestFor,
                             :appointmentID,
                             :bundleID,
                             :callNumber,
                             :documentType,
                             :eadNumber,
                             :format,
                             :forPublication,
                             :itemAuthor,
                             :itemCitation,
                             :itemDate,
                             :itemEdition,
                             :itemInfo1,
                             :itemInfo2,
                             :itemInfo3,
                             :itemInfo4,
                             :itemInfo5,
                             :itemIssue,
                             :itemISxN,
                             :itemNumber,
                             :itemPages,
                             :itemPlace,
                             :itemPublisher,
                             :itemSubTitle,
                             :itemTitle,
                             :itemVolume,
                             :location,
                             :maxCost,
                             :pageCount,
                             :referenceNumber,
                             :reshelvingLocation,
                             :scheduledDate,
                             :serviceLevel,
                             :shippingOption,
                             :site,
                             :specialRequest,
                             :subLocation,
                             :systemID,
                             :webRequestForm,
                             :username,
                             :appointment,
                             :creationDate,
                             :photoduplicationStatus,
                             :photoduplicationDate,
                             :transactionStatus,
                             :transactionDate,
                             :user,
                             :additionalProp1,
                             :additionalProp2,
                             :additionalProp3], coder: JSON

    alias_attribute :transactionNumber, :id

    def as_json(*)
      data.as_json(*).merge({ appointment: appointment, transactionNumber:, creationDate: created_at,
                              transactionDate: transactionDate || updated_at }.as_json(*))
    end

    def appointment
      return if appointmentID.blank?

      StubAeonClient::Appointment.find(appointmentID)
    end
  end
end
