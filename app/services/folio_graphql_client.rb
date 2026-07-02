# frozen_string_literal: true

require 'http'

# Calls the folio-graphql endpoint
class FolioGraphqlClient
  DEFAULT_HEADERS = {
    accept: 'application/json, text/plain',
    content_type: 'application/json'
  }.freeze

  attr_reader :base_url

  def initialize(url: Settings.folio.graphql_url, tenant: Settings.folio.tenant)
    uri = URI.parse(url)

    @username = uri.user
    @password = uri.password
    @base_url = uri.dup.tap do |u|
      u.user = nil
      u.password = nil
    end.to_s

    @tenant = tenant
  end

  def get(path, **)
    request(path, method: :get, **)
  end

  def post(path, **)
    request(path, method: :post, **)
  end

  def get_json(path, **)
    with_retries do
      parse(get(path, **))
    end
  end

  def post_json(path, **)
    with_retries do
      parse(post(path, **))
    end
  end

  # rubocop:disable Metrics/MethodLength
  def circ_check(barcode:)
    post_json('/', json:
      {
        variables: {
          barcode:
        },
        query:
          <<~GQL
            query CircCheckByBarcode($barcode: [String]) {
              items(barcode: $barcode) {
                status {
                  name
                }
                barcode
                dueDate
                effectiveCallNumberComponents {
                  callNumber
                }
                instance {
                  title
                }
              }
            }
          GQL
      })
  end

  def instance_data(hrid:)
    data = post_json('/', json:
    {
      variables: {
        hrid:
      },
      query:
        <<~GQL
          query InstanceByHrid($hrid: [String]) {
            instances(hrid: $hrid) {
              id
              hrid
              title
              queueTotalLength
              identifiers {
                value
                identifierTypeObject {
                  name
                }
              }
              instanceType {
                name
              }
              contributors {
                name
                primary
              }
              publication {
                dateOfPublication
                place
                publisher
              }
              editions
              electronicAccess {
                materialsSpecification
                uri
              }
              holdingsRecords {
                id
                callNumber
                discoverySuppress
                boundWithItem {
                  #{item_fields}

                  queueTotalLength
                  instance {
                    id
                    hrid
                    title
                    instanceType {
                      name
                    }
                  }
                }
                items {
                  #{item_fields}

                  boundWithHoldingsPerItem {
                    id
                    callNumber
                    instance {
                      id
                      title
                      hrid
                      instanceType {
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        GQL
    })
    raise data['errors'].pluck('message').join("\n") if data&.key?('errors')

    data&.dig('data', 'instances', 0)
  end

  def instance(hrid:)
    instance_data = instance_data(hrid:)
    id = instance_data&.dig('id')
    return instance_data unless id

    with_queue_total_length(hrid:, instance_data:)
  end

  def service_points
    data = post_json('/', json:
    {
      query:
    <<~GQL
      query ServicePoints {
        servicePoints {
          pickupLocation
          code
          details {
            isDefaultPickup
            isDefaultForCampus
            notes
          }
          id
          discoveryDisplayName
        }
      }
    GQL
    })

    raise data['errors'].pluck('message').join("\n") if data&.key?('errors')

    data&.dig('data', 'servicePoints')
  end

  def loan_policies
    data = post_json('/', json: {
                       query: "query LoanPolicies {
                                loanPolicies {
                                  id
                                  name
                                  description
                                  renewable
                                  renewalsPolicy {
                                    numberAllowed
                                    alternateFixedDueDateSchedule {
                                      schedules {
                                        due
                                        from
                                        to
                                      }
                                    }
                                    period {
                                      duration
                                      intervalId
                                    }
                                    renewFromId
                                    unlimited
                                  }
                                  loanable
                                  loansPolicy {
                                    period {
                                      duration
                                      intervalId
                                    }
                                    fixedDueDateSchedule {
                                      schedules {
                                        due
                                        from
                                        to
                                      }
                                    }
                                  }
                                  requestManagement {
                                    holds {
                                      renewItemsWithRequest
                                    }
                                  }
                                }
                              }"
                     })

    raise data['errors'].pluck('message').join("\n") if data.key?('errors')

    data.dig('data', 'loanPolicies')
  end

  def extended_user_info(patron_uuid)
    data = post_json('/', json: {
                       query: "query Query($patronId: UUID!) {
                                 user(id: $patronId) {
                                    id
                                    username
                                    barcode
                                    active
                                    personal {
                                      email
                                      lastName
                                      firstName
                                      preferredFirstName
                                    }
                                    proxiesFor {
                                      userId
                                      requestForSponsor
                                      status
                                      expirationDate
                                      user {
                                        id
                                        barcode
                                        personal {
                                          firstName
                                          preferredFirstName
                                          lastName
                                        }
                                      }
                                    }
                                    proxiesOf {
                                      proxyUserId
                                      requestForSponsor
                                      status
                                      expirationDate
                                      proxyUser {
                                        id
                                        barcode
                                        personal {
                                          firstName
                                          preferredFirstName
                                          lastName
                                        }
                                      }
                                    }
                                    expirationDate
                                    externalSystemId
                                    patronGroup {
                                      id
                                      desc
                                      group
                                      limits {
                                        conditionId
                                        id
                                        patronGroupId
                                        value
                                        condition {
                                          blockBorrowing
                                          blockRenewals
                                          blockRequests
                                          message
                                          name
                                          valueType
                                        }
                                      }
                                    }
                                    blocks {
                                      message
                                    }
                                    manualBlocks {
                                      desc
                                    }
                                    patronGroupId
                                  }
                              }",
                       variables: { patronId: patron_uuid }
                     })

    Honeybadger.notify(data['errors'].pluck('message').join("\n"), context: { patron_uuid: }) if data.key?('errors')

    data.dig('data', 'user')
  end

  def extended_patron_info(patron_uuid)
    data = post_json('/', json: {
                       query: "query Query($patronId: UUID!) {
                                patron(id: $patronId) {
                                  id
                                  holds {
                                    requestDate
                                    item {
                                      instanceId
                                      title
                                      itemId

                                      item {
                                        circulationNotes {
                                          id
                                          noteType
                                          note
                                          source {
                                            personal {
                                              lastName
                                            }
                                            id
                                          }
                                          date
                                          staffOnly
                                        }
                                        effectiveShelvingOrder
                                        effectiveCallNumberComponents {
                                          callNumber
                                        }
                                        enumeration
                                        volume
                                        permanentLocation {
                                          code
                                        }
                                        effectiveLocation {
                                          id
                                          code
                                          details {
                                            pageServicePoints {
                                              code
                                              id
                                              discoveryDisplayName
                                              pickupLocation
                                            }
                                          }
                                        }
                                        holdingsRecord {
                                          effectiveLocation {
                                            id
                                            code
                                          }
                                        }
                                      }
                                      author
                                      instance {
                                        hrid

                                        identifiers {
                                          value
                                          identifierTypeObject {
                                            name
                                          }
                                        }
                                      }
                                      isbn
                                    }
                                    requestId
                                    status
                                    expirationDate
                                    details {
                                      holdShelfExpirationDate
                                      proxyUserId
                                      proxy {
                                        firstName
                                        lastName
                                        barcode
                                      }
                                    }
                                    pickupLocationId
                                    pickupLocation {
                                      code
                                    }
                                    queueTotalLength
                                    queuePosition
                                    cancellationReasonId
                                    canceledByUserId
                                    cancellationAdditionalInformation
                                    canceledDate
                                    patronComments
                                  }
                                  accounts {
                                    id
                                    userId
                                    remaining
                                    dateCreated
                                    amount
                                    loanId
                                    loan {
                                      proxyUserId
                                    }
                                    status {
                                      name
                                    }
                                    feeFine {
                                      feeFineType
                                    }
                                    actions {
                                      dateAction
                                      typeAction
                                    }
                                    metadata {
                                      createdDate
                                    }
                                    paymentStatus {
                                      name
                                    }
                                    item {
                                      id
                                      barcode
                                      effectiveShelvingOrder
                                      effectiveLocation {
                                        id
                                        code
                                      }
                                      permanentLocation {
                                        code
                                      }
                                      instance {
                                        title
                                        hrid
                                        contributors {
                                          name
                                        }
                                      }
                                      holdingsRecord {
                                        callNumber
                                        effectiveLocation {
                                          id
                                          code
                                        }
                                      }
                                    }
                                  }
                                  loans {
                                    id
                                    item {
                                      title
                                      author
                                      instanceId
                                      itemId
                                      isbn
                                      instance {
                                        hrid

                                        identifiers {
                                          value
                                          identifierTypeObject {
                                            name
                                          }
                                        }
                                      }
                                      item {
                                        barcode
                                        id
                                        status {
                                          date
                                          name
                                        }
                                        effectiveShelvingOrder
                                        effectiveCallNumberComponents {
                                          callNumber
                                        }
                                        permanentLoanTypeId
                                        temporaryLoanTypeId
                                        materialTypeId
                                        effectiveLocationId
                                        effectiveLocation {
                                          id
                                          code
                                        }
                                        permanentLocation {
                                          code
                                        }
                                        holdingsRecord {
                                          effectiveLocation {
                                            id
                                            code
                                          }
                                        }
                                        queueTotalLength
                                      }
                                    }
                                    loanDate
                                    dueDate
                                    overdue
                                    details {
                                      renewalCount
                                      dueDateChangedByRecall
                                      dueDateChangedByHold
                                      proxyUserId
                                      userId
                                      status {
                                        name
                                      }
                                      feesAndFines {
                                        amountRemainingToPay
                                      }
                                    }
                                  }
                                  totalCharges {
                                    isoCurrencyCode
                                    amount
                                  }
                                  totalChargesCount
                                  totalLoans
                                  totalHolds
                                }
                              }",
                       variables: { patronId: patron_uuid }
                     })

    Honeybadger.notify(data['errors'].pluck('message').join("\n"), context: { patron_uuid: }) if data.key?('errors')

    data.dig('data', 'patron')
  end

  # rubocop:enable Metrics/MethodLength
  def item_fields
    <<-GQL
      id
      barcode
      discoverySuppress
      volume
      status {
        name
      }
      dueDate
      materialType {
        id
        name
      }
      chronology
      enumeration
      effectiveCallNumberComponents {
        callNumber
      }
      notes {
        note
        itemNoteType {
          name
        }
      }
      effectiveLocation {
        id
        campusId
        libraryId
        institutionId
        code
        discoveryDisplayName
        name
        servicePoints {
          id
          code
          pickupLocation
        }
        library {
          id
          code
        }
        campus {
          id
          code
        }
        details {
          pageAeonSite
          pageMediationGroupKey
          pagePreferSendIlliad
          pageServicePoints {
            id
            code
            name
          }
          scanServicePointCode
          availabilityClass
          searchworksTreatTemporaryLocationAsPermanentLocation
        }
      }
      permanentLocation {
        id
        code
        details {
          pageAeonSite
          pageMediationGroupKey
          pagePreferSendIlliad
          pageServicePoints {
            id
            code
            name
          }
          pagingSchedule
          scanServicePointCode
        }
      }
      temporaryLocation {
        id
        code
        discoveryDisplayName
      }
      permanentLoanTypeId
      temporaryLoanTypeId
      holdingsRecord {
        id
        effectiveLocation {
          id
          code
          details {
            pageAeonSite
            pageMediationGroupKey
            pagePreferSendIlliad
            pageServicePoints {
              id
              code
              name
            }
            pagingSchedule
            scanServicePointCode
          }
        }
      }
    GQL
  end

  def ping
    # Every GraphQL server supports the trivial query that asks for the "type name" of the top-level query
    # You can run a health check as a GET against an URL like this
    # See https://www.apollographql.com/docs/apollo-server/monitoring/health-checks/
    request('/graphql?query=%7B__typename%7D').status == 200
  rescue HTTP::Error
    false
  end

  private

  def parse(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def request(path, headers: {}, method: :get, **)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'folio' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'User-Agent': 'FolioGraphqlClient', 'okapi_username' => @username,
                            'okapi_password' => @password })
  end

  def with_queue_total_length(hrid:, instance_data:)
    default = { 'queueTotalLength' => 0 }
    if instance_data['queueTotalLength'].zero?
      # If the instance reports no requests from circ then we can assume the items in that instance also have no requests.
      merge_additional_items_data(instance_data:, additional_data: {}, items_key: 'items', default:)
    else
      merge_additional_items_data(instance_data:, additional_data: items_queue_length(hrid:), items_key: 'items', default:)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def items_queue_length(hrid:)
    data = post_json('/', json:
      {
        variables: {
          hrid:
        },
        query:
        <<~GQL
          query InstanceItemQueueLengthByHrid($hrid: [String]) {
            instances(hrid: $hrid) {
              holdingsRecords {
                items {
                  id
                  queueTotalLength
                }
              }
            }
          }
        GQL
      })

    raise data['errors'].pluck('message').join("\n") if data&.key?('errors')

    data&.dig('data', 'instances', 0)
  end
  # rubocop:enable Metrics/MethodLength

  def items_index_from_instance_data(instance_query_data:, items_key:, records_key:)
    items = []
    Array(instance_query_data[records_key]).each do |record|
      items.concat(Array(record[items_key]))
    end
    items.index_by { |item| item['id'] }
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def merge_additional_items_data(instance_data:, additional_data:, items_key:, records_key: 'holdingsRecords', default: nil)
    return instance_data if instance_data.nil? || additional_data.nil?

    item_data_to_merge = items_index_from_instance_data(instance_query_data: additional_data, items_key:, records_key:)
    Array(instance_data[records_key]).each do |record|
      Array(record[items_key]).each do |item|
        next unless item['id']

        item_data = item_data_to_merge[item['id']] || default
        item.merge!(item_data.except('id')) if item_data
      end
    end

    instance_data
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def with_retries(retries = 5)
    try = 0

    begin
      yield
    rescue JSON::ParserError, HTTP::Error => e
      Honeybadger.notify(e)
      try += 1

      sleep(rand(2**try))

      try <= retries ? retry : raise
    end
  end
end
