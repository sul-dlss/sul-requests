# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper do
  describe '#dialog_column_class' do
    it 'returns a string representing the main dialog class' do
      expect(dialog_column_class).to eq 'col-md-6 col-md-offset-3'
    end
  end

  describe '#bootstrap_form_layout_options' do
    let(:options) { bootstrap_form_layout_options }

    it 'is a horizontal layout' do
      expect(options[:layout]).to eq :horizontal
    end

    it 'defines a custom column class' do
      expect(label_column_class).to eq 'col-sm-4'
      expect(options[:label_col]).to eq label_column_class
    end

    it 'defines a custom column class' do
      expect(content_column_class).to eq 'col-sm-8'
      expect(options[:control_col]).to eq content_column_class
    end
  end

  describe '#label_column_offset_class' do
    it 'is defined to help when offseting non-labeled form elements (e.g. buttons)' do
      expect(label_column_offset_class).to eq 'col-sm-offset-4'
    end
  end

  describe '#send_request_via_login_button' do
    let(:button) { Capybara.string(send_request_via_login_button) }

    it 'returns a button tag' do
      expect(button).to have_css('button[type="submit"]')
    end

    it 'includes an ID' do
      expect(button).to have_css('button#send_request_via_sunet')
    end

    it 'includes the appropriate button classes' do
      expect(button).to have_css('button.btn.btn-primary.btn-full')
    end

    it 'has the appropriate text' do
      expect(button).to have_text(/Send request.*login with SUNet ID/)
    end
  end

  describe '#render_markdown' do
    it 'renders markup to markdown' do
      expect(helper.render_markdown('**abc**')).to include content_tag(:strong, 'abc')
    end
  end

  describe '#render_user_information' do
    before do
      helper.extend(Module.new do
        def current_user; end
      end)

      allow(helper).to receive(:current_user).and_return(user)
    end

    let(:user) { build(:webauth_user, name: 'Some Body') }

    it 'includes the screen reader context' do
      expect(helper.render_user_information).to have_selector '.sr-only', text: 'You are logged in as'
    end

    it 'includes the email for the user' do
      expect(helper.render_user_information).to have_content 'some-webauth-user@stanford.edu'
    end
  end
end
