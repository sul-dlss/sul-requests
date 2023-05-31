class HoldingsRelationshipBuilder
  def self.build(bib_data)
    if bib_data.is_a? Folio::BibData
      Folio::Holdings.new(self, bib_data.instance_id)
    else
      Searchworks::Holdings.new(self, bib_data.holdings)
    end
  end
end