# frozen_string_literal: true

module Folio
  PatronGroup = Data.define(:id, :group, :desc) do
    def self.from_dynamic(dyn)
      new(
        id: dyn.fetch('id'),
        group: dyn['group'],
        desc: dyn['desc']
      )
    end
  end
end
