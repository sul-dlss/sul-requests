# frozen_string_literal: true

# Handle creating a CQL query for FOLIO's API
class CqlQuery
  attr_reader :args, :sortby

  def initialize(sortby: nil, **args)
    @args = args
    @sortby = sortby
  end

  def to_query
    [
      args.map { |k, v| "#{k}==\"#{escape(v)}\"" }.join(' and '),
      ("sortby #{Array(sortby).join(' ')}" if sortby)
    ].compact.join(' ').strip
  end

  private

  def escape(str, characters_to_escape: ['"', '*', '?', '^'], escape_character: '\\')
    str.gsub(Regexp.union(characters_to_escape)) { |x| [escape_character, x].join }
  end
end
