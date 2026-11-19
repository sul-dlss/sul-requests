# frozen_string_literal: true

module Ead
  # Prepares access notes for display without the obsolete request lead time clauses,
  # and omits notes that only state access is unrestricted.
  # Consider discarding this approach after https://github.com/sul-dlss/stanford-arclight/issues/437
  # informs us directly about the nature of each restriction.
  class AccessNotes
    LEAD_TIME = /must\s+be\s+requested\s+at\s+least\s+
                 (?:\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s+
                 (?:hours?|(?:business\s+)?days?)\s+
                 (?:in\s+advance\s+of\s+(?:intended\s+)?use|of\s+intended\s+use)
                 (?:\.\s*|(?=\s*\z))/ix
    MID_SENTENCE_CLAUSE = /(?:;\s*materials?|\s+and)\s+#{LEAD_TIME}/i
    STANDALONE_SENTENCE = /(?:\A|(?<=[.!?]))\s*(?:please\s+)?(?:note\s+that\s+)?materials?\s+#{LEAD_TIME}/i
    UNRESTRICTED = Regexp.union(
      /\A(?:(?:this|the|these) )?(?:(?:collection|materials?|records?|papers|files) (?:is|are) )?open for research(?: use)?[.!]?\z/i,
      /\A(?:none|(?:there are )?no restrictions(?: on access)?|access unrestricted|unrestricted)[.!]?\z/i
    )
    CONTACT_SENTENCE = /\s*contact (?:the )?[\w ]+? for (?:assistance|more information)[.!]?\s*\z/i

    def self.unrestricted?(notes)
      notes.all? { |note| UNRESTRICTED.match?(body_text(note).sub(CONTACT_SENTENCE, '')) }
    end

    def self.body_text(note)
      note.xpath('node()[not(self::head)]').map(&:text).join(' ').squish
    end

    def initialize(notes)
      @notes = notes
    end

    def for_display
      @notes.filter_map { |note| without_lead_time(note) }
    end

    def restrictions
      notes = for_display
      self.class.unrestricted?(notes) ? [] : notes
    end

    private

    def without_lead_time(note)
      copy = note.dup
      copy.xpath('.//text()[not(ancestor::head)]').each do |text|
        text.content = text.content.gsub(MID_SENTENCE_CLAUSE, '. ').gsub(STANDALONE_SENTENCE, ' ')
      end
      copy.xpath('.//p').select { |paragraph| paragraph.text.blank? }.each(&:remove)
      copy if self.class.body_text(copy).present?
    end
  end
end
