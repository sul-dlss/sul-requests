###
#  Mixin to encapsulate defining if a request should be a mediated page
###
module Mediateable
  def mediateable?
    library_is_special_collections? ||
      page_mp? ||
      hopkins_stacks? ||
      hoover_in_sal3?
  end

  private

  def library_is_special_collections?
    @library == 'SPEC-COLL'
  end

  def page_mp?
    @library == 'SAL3' && @location == 'PAGE-MP'
  end

  def hopkins_stacks?
    @library == 'HOPKINS' && @location == 'STACKS'
  end

  def hoover_in_sal3?
    hoover_library_in_sal3? || hoover_archive_in_sal3?
  end

  def hoover_archive_in_sal3?
    @library == 'HV-ARCHIVE' && location_lives_in_sal3?
  end

  def hoover_library_in_sal3?
    @library == 'HOOVER' && location_lives_in_sal3?
  end

  def location_lives_in_sal3?
    @location.ends_with?('-30')
  end
end
