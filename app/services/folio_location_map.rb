# frozen_string_literal: true

require 'csv'

# Similar to https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/locations_map.rb#L18
class FolioLocationMap
  include Singleton
  RENAMES = { 'LANE' => 'LANE-MED' }.freeze

  class NotFound < StandardError; end

  # @return a folio location code
  def self.folio_code_for(library_code:, home_location:)
    locations = instance.translation_data.fetch(library_code)
    locations[home_location]
  rescue KeyError
    raise NotFound
  end

  #
  # @return [Array<String>] a list of folio locations at the given library
  def self.folio_locations(library_code:)
    instance.locations.select { |_, v| v == library_code }.keys
  rescue KeyError
    raise NotFound
  end

  # @return the library code for a location code
  def self.library_code(location:)
    instance.locations.fetch(location)
  rescue KeyError
    raise NotFound, "There is no folio location with the code: '#{location}'"
  end

  def translation_data
    @translation_data ||= load_map
  end

  def library_codes
    @library_codes ||= load_library_codes
  end

  def locations
    @locations ||= load_locations
  end

  def load_map
    CSV.parse(Rails.root.join('lib/translation_maps/locations.tsv').read, col_sep: "\t")
       .each_with_object({}) do |row, result|
      library_code = row[1]
      library_code = RENAMES.fetch(library_code, library_code)

      # SAL3's CDL/ONORDER/INPROCESS locations are all mapped so SAL3-STACKS
      next if row[2] == 'SAL3-STACKS' && row[0] != 'STACKS'

      result[library_code] ||= {}
      result[library_code][row[0]] = row[2]
    end
  end

  def load_locations
    JSON.parse(Rails.root.join('config/folio/locations.json').read).each_with_object({}) do |location, result|
      location_code = location.fetch('code')
      library_id = location.fetch('libraryId')
      result[location_code] = library_codes[library_id]
    end
  end

  def load_library_codes
    JSON.parse(Rails.root.join('config/folio/libraries.json').read).each_with_object({}) do |library, result|
      result[library.fetch('id')] = library.fetch('code')
    end
  end
end
