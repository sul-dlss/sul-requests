require 'rails_helper'

describe ApplicationHelper do
  describe '#dialog_column_class' do
    it 'should return a string representing the main dialog class' do
      expect(dialog_column_class).to eq 'col-md-6 col-md-offset-3'
    end
  end
  describe '#bootstrap_form_layout_options' do
    let(:options) { bootstrap_form_layout_options }
    it 'should be a horizontal layout' do
      expect(options[:layout]).to eq :horizontal
    end
    it 'should define a custom column class' do
      expect(label_column_class).to eq 'col-xs-2'
      expect(options[:label_col]).to eq label_column_class
    end
    it 'should define a custom column class' do
      expect(content_column_class).to eq 'col-xs-10'
      expect(options[:control_col]).to eq content_column_class
    end
  end
  describe '#send_request_via_login_button' do
    let(:button) { Capybara.string(send_request_via_login_button) }
    it 'should return a button tag' do
      expect(button).to have_css('button[type="submit"]')
    end
    it 'should include an ID' do
      expect(button).to have_css('button#send_request_via_sunet')
    end
    it 'should include the appropriate button classes' do
      expect(button).to have_css('button.btn.btn-cardinal.col-xs-12')
    end
    it 'should have the appropriate text' do
      expect(button).to have_text(/Send request.*login with SUNet ID/)
    end
  end
end
