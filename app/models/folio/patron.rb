# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class Patron
    def self.find_by(sunetid: nil, library_id: nil, patron_key: nil, **_kwargs)
      return folio_client.find_patron_by_id(patron_key) if patron_key.present?
      return folio_client.find_patron_by_barcode_or_university_id(library_id) if library_id.present?
      return folio_client.find_patron_by_sunetid(sunetid) if sunetid.present?

      nil
    rescue HTTP::Error
      nil
    end

    def self.folio_client
      FolioClient.new
    end

    attr_reader :user_info

    def initialize(fields = {})
      @user_info = fields
    end

    def id
      user_info.fetch('id')
    end

    def patron_group_id
      # FOLIO APIs return a UUID here
      user_info.fetch('patronGroup')
    end

    # this returns the full patronGroup object
    def patron_group
      Folio::Types.patron_groups[patron_group_id]
    end

    def patron_group_name
      patron_group&.dig('group')
    end

    # always nil for a real patron, but filled in for a PseudoPatron
    def patron_comments; end

    # TODO: I belive we added this for parity with Symphony::Patron, but I don't think we will need it.
    # @deprecated
    def barcode
      user_info['barcode']
    end

    def fee_borrower?
      patron_group_name == 'sul-purchased'
    end

    def ilb_eligible?
      Settings.folio.ilb_eligible_patron_groups.include?(patron_group_name)
    end

    def standing
      user_info.dig('standing', 'key')
    end

    def make_request_as_patron?
      !expired? && patron_group_id.present?
    end

    def first_name
      user_info.dig('personal', 'preferredFirstName') || user_info.dig('personal', 'firstName')
    end

    def last_name
      user_info.dig('personal', 'lastName')
    end

    def display_name
      [first_name, last_name].join(' ')
    end

    def email
      user_info.dig('personal', 'email')
    end

    def proxy_email_address
      proxy_info&.dig('notificationsTo') || email
    end

    def expired?
      user_info['active'] == false
    end

    def proxy?
      proxy_info.present?
    end

    def sponsor?
      proxy_group_info.present?
    end

    def proxy_sponsor_user_id
      proxy_info&.dig('userId')
    end

    def university_id
      user_info['externalSystemId']
    end

    def blocked?
      patron_blocks.fetch('automatedPatronBlocks').present?
    end

    def blocks
      blocks = patron_blocks.fetch('automatedPatronBlocks')
      blocks.map { |block| construct_message(block['message']) }
    end

    def construct_message(message)
      base_messaging = 'You can request these items, but the request will not be fufilled until you'
      case message
      when /fines/
        "You have #{number_of_fines} outstanding fines. #{base_messaging} pay your outstanding balance of $#{format('%.2f', fines)}"
      when /overdue/
        "You have #{overdue_items.length} overdue items. #{base_messaging} pay for or return these items."
      else
        message
      end
    end

    def fines
      patron_summary['totalCharges']['amount']
    end

    def number_of_fines
      patron_summary['totalChargesCount']
    end

    def overdue_items
      patron_summary['loans'].map { |loan| (loan['dueDate'].to_datetime - DateTime.now).negative? }
    end

    def exists?
      user_info.present?
    end

    def allowed_request_types(item)
      policy_service.item_request_policy(item)&.dig('requestTypes') || []
    end

    def policy_service
      @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [patron_group_id])
    end

    private

    def patron_summary
      @patron_summary ||= self.class.folio_client.patron_summary(id)
    end

    def patron_blocks
      @patron_blocks ||= self.class.folio_client.patron_blocks(id)
    end

    def proxy_info
      @proxy_info ||= self.class.folio_client.proxy_info(id)
    end

    def proxy_group_info
      @proxy_group_info ||= self.class.folio_client.proxy_group_info(id)
    end
  end
end
