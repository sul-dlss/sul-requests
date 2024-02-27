# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper do
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

  describe '#sort_holdings_records' do
    let(:all_items) do
      [
        double('item', callnumber: 'ABC 123', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                       pageable?: true, mediateable?: false, barcode: '123123124', checked_out?: false, status_class: 'active',
                       enumeration: rec_one_enumeration, callnumber_no_enumeration: 'ABC 123',
                       status_text: 'Active', public_note: 'huh?', type: 'STKS', effective_location: build(:location), requestable?: true,
                       permanent_location: build(:location), material_type: build(:book_material_type), loan_type: double(id: nil)),
        double('item', callnumber: 'ABC 123', processing?: false, missing?: false, hold?: false, on_order?: false, hold_recallable?: false,
                       pageable?: true, mediateable?: false, barcode: '9928812', checked_out?: false, status_class: 'active',
                       enumeration: rec_two_enumeration, callnumber_no_enumeration: 'ABC 123',
                       status_text: 'Active', public_note: 'huh?', type: 'STKS', effective_location: build(:location), requestable?: true,
                       permanent_location: build(:location), material_type: build(:book_material_type), loan_type: double(id: nil))
      ]
    end
    let(:sorted_holdings) { sort_holdings(all_items) }

    context 'when date with volume' do
      let(:rec_one_enumeration) { 'V12 2020' }
      let(:rec_two_enumeration) { 'V12 2021' }

      it 'expects to sort desc by date' do
        expect(sorted_holdings.first.barcode).to equal('9928812')
      end
    end

    context 'when volume with letter' do
      let(:rec_one_enumeration) { 'V12' }
      let(:rec_two_enumeration) { 'V12A' }

      it 'expects sort asc by volume and letter' do
        expect(sorted_holdings.first.barcode).to equal('123123124')
      end
    end

    context 'when one item has no enumeration' do
      let(:rec_one_enumeration) { '' }
      let(:rec_two_enumeration) { '12' }

      it 'expects items with no enumeration first' do
        expect(sorted_holdings.first.barcode).to equal('123123124')
      end
    end

    context 'when there are months in barcode' do
      let(:rec_one_enumeration) { 'JANUARY-MARCH 2021' }
      let(:rec_two_enumeration) { 'Dec 2020:Apr 2021' }

      it 'expects newest month/year combo to be first' do
        expect(sorted_holdings.first.barcode).to equal('9928812')
      end
    end

    context 'when there are months, years, and volumes in barcode' do
      let(:rec_one_enumeration) { 'JANUARY-MARCH 2021 1' }
      let(:rec_two_enumeration) { 'Feb-MARCH 2021 12' }

      it 'expects to sort by volume due to same end month' do
        expect(sorted_holdings.first.barcode).to equal('123123124')
      end
    end
  end

  describe '#render_user_information' do
    before do
      helper.extend(Module.new do
        def current_user; end
      end)

      allow(helper).to receive(:current_user).and_return(user)
    end

    let(:user) { build(:sso_user, name: 'Some Body') }

    it 'includes the screen reader context' do
      expect(helper.render_user_information).to have_css '.sr-only', text: 'You are logged in as'
    end

    it 'includes the email for the user' do
      expect(helper.render_user_information).to have_content 'some-sso-user@stanford.edu'
    end
  end
end
