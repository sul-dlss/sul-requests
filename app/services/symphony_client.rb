# frozen_string_literal: true

# HTTP client wrapper for making requests to Symws
class SymphonyClient
  DEFAULT_HEADERS = {
    accept: 'application/json',
    content_type: 'application/json'
  }.freeze

  # ping the symphony endpoint to make sure we can establish a connection
  def ping
    session_token.present?
  rescue HTTP::Error
    false
  end

  def login(library_id, pin)
    response = authenticated_request('/user/patron/authenticate', method: :post, json: {
                                       barcode: library_id,
                                       password: pin
                                     })

    JSON.parse(response.body)
  end

  def login_by_sunetid(sunetid)
    response = authenticated_request('/user/patron/search', params: {
                                       q: "webAuthID:#{sunetid}",
                                       includeFields: '*'
                                     })

    JSON.parse(response.body)['result'].first
  rescue JSON::ParserError
    nil
  end

  def login_by_library_id(library_id)
    response = authenticated_request('/user/patron/search', params: {
                                       q: "id:#{library_id}",
                                       includeFields: '*'
                                     })

    JSON.parse(response.body)['result']&.first
  rescue JSON::ParserError
    nil
  end

  # get a session token by authenticating to symws
  def session_token
    @session_token ||= begin
      response = request('/user/staff/login', json: Settings.symws.login_params, method: :post)

      JSON.parse(response.body)['sessionToken']
    rescue JSON::ParserError
      Honeybadger.notify('Unable to connect to Symphony Web Services.')
      nil
    end
  end

  def catalog_info(key)
    headers = if Settings.symws.headers
                {}
              else
                guest_headers
              end

    response = authenticated_request("/catalog/item/barcode/#{ERB::Util.url_encode(key)}", params: {
                                       includeFields: [
                                         '*',
                                         'bib{holdRecordList{*,item{call,bib{title}}}}',
                                         'call{*,itemList{*}}',
                                         'currentLocation'
                                       ].join(',')
                                     }, headers: headers)

    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  def bib_info(key)
    response = authenticated_request("/catalog/bib/key/#{key}", params: {
                                       includeFields: '*,callList{*}'
                                     })
    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  def hold_record_info(key)
    response = authenticated_request("/circulation/holdRecord/key/#{key}", params: {
                                       includeFields: '*,patron{email},item{call,bib{title}}'
                                     })
    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  def place_hold(**params)
    response = authenticated_request(
      '/circulation/holdRecord/placeHold',
      method: :post,
      params: { includeFields: 'holdRecord{*,item{call,bib{title}}}' },
      **place_hold_params(**params, override_code: Settings.symphony.override)
    )
    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  def circ_information(item_barcode)
    response = authenticated_request('/circulation/itemCircInfo/advise', method: :post, json: {
                                       itemBarcode: item_barcode
                                     })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end

  def update_hold(hold_record_key, comment:)
    response = authenticated_request(
      "/circulation/holdRecord/key/#{hold_record_key}",
      method: :put,
      json: {
        resource: '/circulation/holdRecord',
        key: hold_record_key,
        fields: {
          comment: comment
        }
      }
    )
    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  def check_in_item(item_barcode)
    response = authenticated_request('/circulation/circRecord/checkIn', method: :post, json: {
                                       itemBarcode: item_barcode
                                     })
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end

  def check_out_item(item_barcode, _patron_barcode, **params)
    sd_prompt_return = [
      "CIRC_NONCHARGEABLE_OVRCD/#{Settings.symphony.override}",
      "HOLD_NO_HOLDS_OVRCD/#{Settings.symphony.override}",
      "CKOBLOCKS/#{Settings.symphony.override}",
      "CIRC_HOLDS_OVRCD/#{Settings.symphony.override}"
    ]
    response = authenticated_request('/circulation/circRecord/checkOut', method: :post, params: {
                                       includeFields: 'circRecord{*,item{barcode}}'
                                     }, json: {
                                       itemBarcode: item_barcode,
                                       # patronBarcode: patron_barcode
                                       # Using patron key here instead of barcode due to a Symphony
                                       # Web Services bug where the transaction is not reported in
                                       # statistics logs.
                                       patron: {
                                         resource: '/user/patron',
                                         key: Settings.cdl.pseudo_patron_key
                                       }
                                     }.merge(params), headers: {
                                       'SD-Prompt-Return': sd_prompt_return.join(';'),
                                       'SD-Working-LibraryID': 'SUL'
                                     })
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end

  def edit_circ_record_info(circ_record_key, **params)
    response = authenticated_request(
      "/circulation/circRecord/key/#{circ_record_key}",
      method: :put,
      json: {
        resource: '/circulation/circRecord',
        key: circ_record_key,
        fields: params
      }
    )
    JSON.parse(response.body)
  rescue JSON::ParserError, HTTP::Error
    nil
  end

  def renew_item(item_barcode, patron_barcode, **params)
    sd_prompt_return = [
      "CIRC_NONCHARGEABLE_OVRCD/#{Settings.symphony.override}",
      "HOLD_NO_HOLDS_OVRCD/#{Settings.symphony.override}",
      "CKOBLOCKS/#{Settings.symphony.override}",
      "CIRC_HOLDS_OVRCD/#{Settings.symphony.override}",
      "CIRC_UNSEEN_RENEW_LIMIT_OVRCD/#{Settings.symphony.override}"
    ]
    response = authenticated_request('/circulation/circRecord/renew', method: :post, params: {
                                       includeFields: 'circRecord{*,item{barcode}}'
                                     }, json: {
                                       item: {
                                         key: item_barcode,
                                         resource: '/catalog/item'
                                       },
                                       patronBarcode: patron_barcode, **params
                                     }, headers: {
                                       'SD-Prompt-Return': sd_prompt_return.join(';'),
                                       'SD-Working-LibraryID': 'SUL'
                                     })
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end

  # rubocop:disable Metrics/ParameterLists
  def place_hold_params(
    fill_by_date:, key: 'GREEN', recall_status: 'STANDARD',
    item: {}, patron_barcode:, comment:,
    for_group: false, force: true, override_code: '*****'
  )
    sd_prompt_return = ["GROUP_PROMPT/#{for_group}"]
    sd_prompt_return << "HOLD_NO_HOLDS_OVRCD/#{override_code}" if force

    {
      json: {
        comment: comment.truncate(50, omission: ''),
        fillByDate: (fill_by_date || DateTime.now + 3.years).strftime('%Y-%m-%d'),
        holdRange: 'SYSTEM',
        patronBarcode: patron_barcode,
        pickupLibrary: {
          key: key,
          resource: '/policy/library'
        },
        recallStatus: recall_status
      }.merge(item),
      headers: {
        'SD-Prompt-Return': sd_prompt_return.join(';'),
        'SD-Working-LibraryID': 'SUL'
      }
    }
  end
  # rubocop:enable Metrics/ParameterLists

  def cancel_hold(hold_record_id)
    response = authenticated_request('/circulation/holdRecord/cancelHold', method: :post, json: {
                                       holdRecord: {
                                         resource: '/circulation/holdRecord',
                                         key: hold_record_id
                                       }
                                     })
    begin
      JSON.parse(response)
    rescue JSON::ParserError, HTTP::Error
      nil
    end
  end

  def patron_info(patron_key)
    response = authenticated_request("/user/patron/key/#{patron_key}", params: {
                                       includeFields: [
                                         '*',
                                         'address1',
                                         'profile{chargeLimit}',
                                         'customInformation{*}',
                                         'groupSettings{*,group{memberList{*,address1}}}',
                                         'holdRecordList{*,item{call,bib{title}}}'
                                       ].join(',')
                                     })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end

  def checkouts(patron_key)
    response = authenticated_request("/user/patron/key/#{patron_key}", params: {
                                       includeFields: [
                                         'circRecordList{*}'
                                       ].join(',')
                                     })

    begin
      JSON.parse(response.body)&.dig('fields', 'circRecordList') || []
    rescue JSON::ParserError
      []
    end
  end

  def circ_record_info(circ_record_key, return_holds: false)
    hold_return = return_holds ? 'item{barcode,call,bib{holdRecordList{*,item{call,bib{title}}}}}' : 'item{barcode}'
    response = authenticated_request("/circulation/circRecord/key/#{circ_record_key}", params: {
                                       includeFields: [
                                         '*',
                                         'patron{barcode}',
                                         hold_return
                                       ].join(',')
                                     })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end
  end

  private

  def response_prompt(response)
    return if response.status.ok?

    JSON.parse(response.body).dig('dataMap', 'promptType')
  rescue JSON::ParserError
    nil
  end

  def authenticated_request(path, headers: {}, **other)
    request(path, headers: headers.merge('x-sirs-sessionToken': session_token), **other)
  end

  # rubocop:disable Metrics/AbcSize
  def request(path, headers: {}, method: :get, **other)
    Honeybadger.add_breadcrumb('Symphony request', metadata: {
                                 path: path,
                                 params: other[:params].to_json,
                                 json: other[:json].to_json
                               })

    response = HTTP
               .timeout(60)
               .use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter, namespace: 'symphony' })
               .headers(default_headers.merge(headers))
               .request(method, base_url + path, **other)

    Honeybadger.add_breadcrumb('Symphony response', metadata: { body: response.body.to_s })

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Honeybadger.notify(e)
    end

    # let the specific API methods figure out what fallback to apply
    response
  rescue HTTP::Error => e
    Honeybadger.notify(e)

    # let the specific API methods figure out what fallback to apply
    raise e
  end
  # rubocop:enable Metrics/AbcSize

  def base_url
    Settings.symws.url
  end

  def default_headers
    DEFAULT_HEADERS.merge(Settings.symws.headers || {})
  end

  def guest_headers
    {
      'x-sirs-clientID': 'DS_CLIENT',
      'sd-originating-app-id': 'requests',
      'SD-Preferred-Role': 'GUEST'
    }
  end
end
