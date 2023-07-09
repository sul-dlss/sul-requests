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

  def get(path, **kwargs)
    request(path, method: :get, **kwargs)
  end

  def post(path, **kwargs)
    request(path, method: :post, **kwargs)
  end

  def get_json(path, **kwargs)
    parse(get(path, **kwargs))
  end

  def post_json(path, **kwargs)
    parse(post(path, **kwargs))
  end

  # rubocop:disable Metrics/MethodLength
  def instance(hrid:)
    data = post_json('/', json:
    {
      query:
        <<~GQL
          query InstanceByHrid {
            instances(hrid: "#{hrid}") {
              id
              title
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
              }
              electronicAccess {
                materialsSpecification
                uri
              }
              items {
                barcode
                status {
                  name
                }
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
                  details {
                    pageAeonSite
                    pageMediationGroupKey
                    pageServicePoints {
                      id
                      code
                      name
                    }
                  }
                }
                permanentLoanTypeId
                temporaryLoanTypeId
              }
            }
          }
        GQL
    })
    raise data['errors'].pluck('message').join("\n") if data&.key?('errors')

    data&.dig('data', 'instances', 0)
  end
  # rubocop:enable Metrics/MethodLength

  def ping
    # Every GraphQL server supports the trivial query that asks for the "type name" of the top-level query
    # You can run a health check as a GET against an URL like this
    # See https://www.apollographql.com/docs/apollo-server/monitoring/health-checks/
    request('/graphql?query=%7B__typename%7D')
  rescue HTTP::Error
    false
  end

  private

  def parse(response)
    return nil if response.body.empty?

    JSON.parse(response.body)
  end

  def request(path, headers: {}, method: :get, **other)
    HTTP
      .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'folio' })
      .headers(default_headers.merge(headers))
      .request(method, base_url + path, **other)
  end

  def default_headers
    DEFAULT_HEADERS.merge({ 'User-Agent': 'FolioGraphqlClient', 'okapi_username' => @username,
                            'okapi_password' => @password })
  end
end
