# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class User < AeonRecord
    store :data, accessors: [:lastName,
                             :firstName,
                             :dateOfBirth,
                             :id,
                             :idType,
                             :altID,
                             :altIDType,
                             :status,
                             :department,
                             :organization,
                             :eMailAddress,
                             :phone,
                             :fax,
                             :authType,
                             :registrationStatus,
                             :notificationMethod,
                             :deliveryMethod,
                             :expirationDate,
                             :address,
                             :address2,
                             :city,
                             :state,
                             :zip,
                             :country,
                             :billingCategory,
                             :rssid,
                             :sAddress,
                             :sAddress2,
                             :sCity,
                             :sState,
                             :sZip,
                             :sCountry,
                             :cleared,
                             :requestLimit,
                             :researchTopics,
                             :researchTopicsSharing,
                             :userInfo1,
                             :userInfo2,
                             :userInfo3,
                             :userInfo4,
                             :userInfo5,
                             :preferredName,
                             :lastChangedDate,
                             :imageID,
                             :creationDate,
                             :additionalProp1,
                             :additionalProp2,
                             :additionalProp3], coder: JSON

    def as_json(*)
      data.as_json(*).merge('username' => username)
    end
  end
end
