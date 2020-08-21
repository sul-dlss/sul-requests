# frozen_string_literal: true

# Accessing bibliographic information from the symphony response
class BibInfo
  def initialize(response)
    @response = response
  end

  def title
    fields.dig('title')
  end

  def author
    fields.dig('author')
  end

  def pub_year
    marc008 = marc('008').first&.dig('subfields', 0, 'data')
    marc008 && marc008[7..10]
  end

  def marc(tag)
    (fields.dig('bib', 'fields') || []).select { |field| field['tag'] == tag }
  end

  def fields
    (@response || {}).dig('fields') || {}
  end
end
