# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitSymphonyRequestJob, type: :job do
  describe '#perform' do
    it 'enqueues a folio job' do
      expect(SubmitFolioRequestJob).to receive(:perform_later).with('123', { foo: 'bar' })
      subject.perform('123', foo: 'bar')
    end
  end
end
