# frozen_string_literal: true

require 'rails_helper'

describe ExpireCdlCheckoutsJob, type: :job do
  pending 'checks in overdue items' do
    expect(true).to be_falsy
  end

  pending 'cancels any "active" hold on the item'
end
