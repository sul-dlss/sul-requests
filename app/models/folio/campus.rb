# frozen_string_literal: true

module Folio
  Campus = Data.define(:id, :code) do
    def self.from_dynamic(dyn)
      new(id: dyn.fetch('id'), code: dyn['code'])
    end
  end
end
