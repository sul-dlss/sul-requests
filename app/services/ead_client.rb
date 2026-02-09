# frozen_string_literal: true

##
# Service class for fetching EAD XML files
class EadClient
  attr_reader :url, :doc

  class Error < StandardError
  end

  def self.fetch(url)
    response = Faraday.get(url)

    raise "Failed to fetch EAD XML: HTTP #{response.code}" unless response.success?

    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!

    Ead::Document.new(doc, url: url)
  rescue URI::InvalidURIError => e
    raise EadClient::Error, "Invalid URL provided: #{e.message}"
  rescue StandardError => e
    raise EadClient::Error, "Error fetching EAD XML: #{e.message}"
  rescue Nokogiri::XML::SyntaxError => e
    raise EadClient::Error, "Invalid XML format: #{e.message}"
  end
end
