# frozen_string_literal: true

##
# Service class for fetching EAD XML files
class EadClient
  class Error < StandardError
  end

  def self.fetch(url)
    new.fetch(url)
  end

  def fetch(url)
    cache_key = ['ead_client', url]
    begin
      xml = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
        get(url).body
      end

      doc = Nokogiri::XML(xml).tap(&:remove_namespaces!)

      Ead::Document.new(doc, url: url)
    rescue Nokogiri::XML::SyntaxError => e
      Rails.cache.delete(cache_key)

      raise EadClient::Error, "Invalid XML format: #{e.message}"
    end
  end

  private

  def get(url)
    response = Faraday.get(url)

    raise EadClient::Error, "Failed to fetch EAD XML: HTTP #{response.code}" unless response.success?

    response
  end
end
