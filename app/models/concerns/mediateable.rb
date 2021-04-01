# frozen_string_literal: true

###
#  Mixin to encapsulate defining if a request should be a mediated page
###
module Mediateable
  MEDIATALBE_LIBRARIES = ['RUMSEYMAP', 'SPEC-COLL'].freeze
  ART_LOCKED_STACKS_LOCATIONS = %w[ARTLCKL ARTLCKL-R ARTLCKM ARTLCKM-R ARTLCKO ARTLCKO-R ARTLCKS ARTLCKS-R].freeze
  EDUCATION_LOCKED_STACKS_LOCATIONS = ['LOCKED-STK'].freeze

  def mediateable?
    mediated_library? ||
      art_locked_stacks? ||
      page_mp? ||
      hoover_archive_in_sal3? ||
      education_locked_stacks?
  end

  private

  def mediated_library?
    MEDIATALBE_LIBRARIES.include?(@library)
  end

  def art_locked_stacks?
    @library == 'ART' && ART_LOCKED_STACKS_LOCATIONS.include?(@location)
  end

  def page_mp?
    @library == 'SAL3' && @location == 'PAGE-MP'
  end

  def hoover_archive_in_sal3?
    @library == 'HV-ARCHIVE' && location_lives_in_sal3?
  end

  def location_lives_in_sal3?
    @location.ends_with?('-30')
  end

  def education_locked_stacks?
    @library == 'EDUCATION' && EDUCATION_LOCKED_STACKS_LOCATIONS.include?(@location)
  end
end
