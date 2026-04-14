# frozen_string_literal: true

##
# Service class for fetching EAD XML files
class EadClient
  class Error < StandardError; end
  class InvalidDocument < Error; end

  def self.fetch(url)
    new.fetch(url)
  end

  def fetch(url)
    cache_key = ['ead_client', url]
    xml = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
      get(url).body
    end
    parse_ead(xml, url:)
  rescue Nokogiri::XML::SyntaxError => e
    Rails.cache.delete(cache_key)
    raise EadClient::InvalidDocument, "Invalid XML format: #{e.message}"
  end

  private

  def get(url)
    response = Faraday.get(url)

    raise EadClient::Error, "Failed to fetch EAD XML: HTTP #{response.status}" unless response.success?

    response
  end

  def parse_ead(xml, url:)
    doc = Nokogiri::XML(xml).tap(&:remove_namespaces!)
    raise EadClient::InvalidDocument, 'Not a valid EAD document' if doc.root&.name != 'ead'

    Ead::Document.new(doc, url:)
  end
end
