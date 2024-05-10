# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request do
  subject(:request) { described_class.new(item_id: '1234', origin: 'GREEN', origin_location: 'SAL3-STACKS') }

  let(:items) { [] }
  let(:instance) { instance_double(Folio::Instance, title: 'Test title', request_holdings: items, items: []) }
  let(:default_destination) { 'GREEN-LOAN' }

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(instance)
  end

  describe 'scopes' do
    describe '.for_date' do
      before do
        create(:request, needed_date: Time.zone.today + 1.day)
        create(:request, needed_date: Time.zone.today + 1.day)
        create(:request, needed_date: Time.zone.today + 2.days)
      end

      it 'returns requests with needed_date matching the given date' do
        expect(described_class.for_date(Time.zone.today + 1.day).count).to eq 2
        expect(described_class.for_date(Time.zone.today + 2.days).count).to eq 1
      end
    end

    describe '.for_create_date' do
      before do
        create(:request, created_at: Time.zone.today - 1.day)
        create(:request, created_at: Time.zone.today - 1.day)
        create(:request, created_at: Time.zone.today - 2.days)
      end

      it 'returns requests with created_at matching the given date' do
        expect(described_class.for_create_date((Time.zone.today - 1.day).to_s).count).to eq 2
        expect(described_class.for_create_date((Time.zone.today - 2.days).to_s).count).to eq 1
      end
    end

    describe '.needed_date_desc' do
      before do
        create(:request, needed_date: Time.zone.today + 1.day)
        create(:request, needed_date: Time.zone.today + 3.days)
        create(:request, needed_date: Time.zone.today + 2.days)
      end

      it 'returns records in descending needed date order' do
        sorted = described_class.needed_date_desc.limit(3)
        expect(sorted[0].needed_date).to eq Time.zone.today + 3.days
        expect(sorted[1].needed_date).to eq Time.zone.today + 2.days
        expect(sorted[2].needed_date).to eq Time.zone.today + 1.day
      end
    end

    describe '.obsolete' do
      before do
        create(:hold_recall, created_at: Time.zone.today - 1.month, item_comment: 'Too new')
        create(:hold_recall, created_at: Time.zone.today - 2.years, item_comment: 'Obsolete')
        create(:scan, :without_validations, created_at: Time.zone.today + 3.days, item_comment: 'Too new')
        create(:scan, :without_validations, created_at: Time.zone.today - 15.months, item_comment: 'Obsolete')
        r = build(:mediated_page, created_at: Time.zone.today - 15.months,
                                  needed_date: Time.zone.today - 83.days,
                                  item_comment: 'Old enough, but needed date too recent')
        r.save!(validate: false)
        r = build(:mediated_page, created_at: Time.zone.today - 15.months,
                                  needed_date: Time.zone.today - 13.months,
                                  item_comment: 'Obsolete')
        r.save!(validate: false)
      end

      it 'returns records that are older than the given date' do
        result = described_class.obsolete(1.year.ago)
        expect(result.count).to eq 3
        expect(result.map(&:item_comment).uniq).to contain_exactly('Obsolete')
      end
    end
  end

  describe 'associations' do
    it 'has many admin comments' do
      request = create(:request)
      admin_comment = AdminComment.create!(comment: 'The Comment', commenter: 'user')
      request.admin_comments = [admin_comment]
      request.save!
      expect(request.admin_comments).to eq([admin_comment])
    end
  end

  describe '#paging_origin_library' do
    subject { request.paging_origin_library }

    let(:request) { described_class.new(origin: 'GREEN', item_id: '12345') }

    context 'when not a folio instance' do
      it { is_expected.to eq 'GREEN' }
    end

    context 'when the folio instance' do
      let(:instance) { instance_double(Folio::Instance, items:) }

      let(:items) do
        [instance_double(Folio::Item, permanent_location:)]
      end

      context 'with pagingSchedule set' do
        let(:permanent_location) { instance_double(Folio::Location, details: { 'pagingSchedule' => 'SAL3' }) }

        it { is_expected.to eq 'SAL3' }
      end

      context 'without pagingSchedule set' do
        let(:permanent_location) { instance_double(Folio::Location, details: {}) }

        it { is_expected.to eq 'GREEN' }
      end
    end
  end

  describe '#library_location' do
    it 'returns a library_location object' do
      expect(subject.library_location).to be_a LibraryLocation
    end
  end

  describe '#holdings' do
    describe 'when persisted' do
      let(:subject) { create(:request_with_multiple_holdings, barcodes: ['3610512345678']) }
      let(:items) { [double('item', barcode: '3610512345678')] }

      it 'gets the holdings from the requested location by the persisted barcodes' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings.length).to eq 1
        expect(holdings.first.barcode).to eq '3610512345678'
      end
    end

    describe 'when persisted with no selected barcode' do
      let(:subject) { build_stubbed(:request_with_multiple_holdings, barcodes: []) }

      it 'gets all the holdings for the requested location' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings).to be_blank
      end
    end

    describe 'when not persisted' do
      subject(:request) { build(:request_with_multiple_holdings) }

      it 'gets all the holdings for the requested location' do
        holdings = request.holdings
        expect(holdings.count).to eq 3
        expect(holdings.first.barcode).to eq '3610512345678'
        expect(holdings.to_a.last.barcode).to eq '12345679'
      end
    end
  end

  describe '#all_holdings' do
    subject(:all_holdings) { request.all_holdings }

    let(:request) { build(:request_with_multiple_holdings, barcodes: ['3610512345678']) }
    let(:items) do
      [double('item', barcode: '3610512345678'), double('item'), double('item', barcode: '12345679')]
    end

    it 'gets all the holdings for the requested location' do
      expect(all_holdings.count).to eq 3
      expect(all_holdings.first.barcode).to eq '3610512345678'
      expect(all_holdings.to_a.last.barcode).to eq '12345679'
    end
  end

  describe '#requested_holdings' do
    subject(:holdings) { request.requested_holdings }

    let(:request) { create(:request_with_multiple_holdings, barcodes: ['3610512345678']) }
    let(:items) { [double('item', barcode: '3610512345678')] }

    it 'gets the holdings from the requested location by the persisted barcodes' do
      expect(holdings).to be_a Array
      expect(holdings.length).to eq 1
      expect(holdings.first.barcode).to eq '3610512345678'
    end
  end

  describe '#data_to_email_s' do
    subject { Scan.new }

    it 'turns the serialized data hash into a string' do
      subject.data = { 'page_range' => 'Range', 'authors' => 'Authors' }
      expect(subject.data_to_email_s).to include('Page range:')
      expect(subject.data_to_email_s).to include('Range')

      expect(subject.data_to_email_s).to include('Author(s):')
      expect(subject.data_to_email_s).to include('Authors')
    end
  end

  describe 'nested attributes for' do
    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: '12345').and_return(
        instance_double(Folio::Patron, exists?: true)
      )
    end

    describe 'users' do
      it 'handles SSO users (w/o emails) correctly' do
        User.create!(sunetid: 'a-sso-user')
        sso_user = User.new(sunetid: 'current-sso-user')
        allow_any_instance_of(described_class).to receive_messages(user: sso_user)
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'GRE-STACKS'
        )
        expect(described_class.last.user).to eq User.last
      end

      it 'creates new users' do
        expect(User.find_by_email('jstanford@stanford.edu')).to be_nil
        described_class.create(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'GRE-STACKS',
          user_attributes: {
            name: 'Jane Stanford',
            email: 'jstanford@stanford.edu'
          }
        )
        expect(User.find_by_email('jstanford@stanford.edu')).to be_present
      end

      it 'does not duplicate users email addresses' do
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 0
        User.create(email: 'jstanford@stanford.edu')
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 1
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'GRE-STACKS',
          user_attributes: {
            name: 'Jane Stanford',
            email: 'jstanford@stanford.edu'
          }
        )
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 1
      end

      it 'updates email users name' do
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 0
        User.create(email: 'jstanford@stanford.edu', name: 'J. Stanford')
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 1
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'GRE-STACKS',
          user_attributes: {
            name: 'Jane Stanford',
            email: 'jstanford@stanford.edu'
          }
        )

        expect(User.find_by(email: 'jstanford@stanford.edu').name).to eq 'Jane Stanford'
      end

      it 'does not duplicate user records when both library ID and email is provided' do
        expect(User.where(library_id: '12345', email: 'jstanford@stanford.edu').length).to eq 0
        User.create(library_id: '12345', email: 'jstanford@stanford.edu')
        expect(User.where(library_id: '12345', email: 'jstanford@stanford.edu').length).to eq 1
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'GRE-STACKS',
          user_attributes: {
            library_id: '12345',
            email: 'jstanford@stanford.edu'
          }
        )
        expect(User.where(library_id: '12345', email: 'jstanford@stanford.edu').length).to eq 1
      end

      it 'does not use existing user records when a name+email is provded' do
        bad_id = '54321'
        # User is already created with a bad library ID
        User.create(library_id: bad_id, email: 'jstanford@stanford.edu')
        expect(User.where(library_id: bad_id, email: 'jstanford@stanford.edu').length).to eq 1
        # User comes in and just adds a name+email with the same email address as the bad ID
        expect do
          described_class.create!(
            item_id: '1234',
            origin: 'GREEN',
            origin_location: 'GRE-STACKS',
            user_attributes: {
              name: 'Jane Stanford',
              email: 'jstanford@stanford.edu'
            }
          )
        end.to change(User, :count).by(1)
      end

      it 'does not duplicate library ids' do
        expect(User.where(library_id: '12345').length).to eq 0
        User.create(library_id: '12345')
        expect(User.where(library_id: '12345').length).to eq 1
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'GRE-STACKS',
          user_attributes: {
            library_id: '12345'
          }
        )
        expect(User.where(library_id: '12345').length).to eq 1
      end
    end
  end

  describe 'item_title' do
    context 'when the title is not present' do
      before do
        allow(Settings.ils.bib_model.constantize).to receive(:fetch)
          .and_return(double(:bib_data, title: 'When do you need an antacid? : a burning question', request_holdings: []))
      end

      it 'fetches the item title' do
        described_class.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'GRE-STACKS')
        expect(described_class.last.item_title).to eq 'When do you need an antacid? : a burning question'
      end
    end

    context 'when the title is present' do
      it 'does not fetch the title' do
        described_class.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'GRE-STACKS', item_title: 'This title')
        expect(described_class.last.item_title).to eq 'This title'
      end
    end

    it 'returns the stored item title for persisted objects' do
      expect(create(:request).item_title).to eq 'Title for Request 123456'
    end

    it 'returns the item title from the fetched Folio record' do
      allow_any_instance_of(described_class).to receive(:bib_data)
        .and_return(instance_double(described_class.bib_model_class, title: 'A fetched title'))
      expect(described_class.new.item_title).to eq 'A fetched title'
    end
  end

  describe '#delegate_request!' do
    before do
      stub_bib_data_json(build(:multiple_holdings))
      subject.update(origin: 'SAL3', origin_location: 'SAL3-STACKS')
    end

    it 'delegates to a mediated page if it is mediateable' do
      allow(subject).to receive_messages(mediateable?: true)
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'MediatedPage'
    end

    it 'delegates to a hold recall if it is hold recallable' do
      allow(subject).to receive_messages(hold_recallable?: true)
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'HoldRecall'
    end

    it 'delegates to a page request otherwise' do
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'Page'
    end
  end

  describe '#data' do
    let(:data_hash) { { 'a' => 'a', 'b' => 'b' } }

    it 'is a serialized hash' do
      expect(subject.data).to eq({})
      subject.data = data_hash
      expect(subject.data).to eq data_hash
    end

    it 'copes with nested hashes (e.g. public_notes)' do
      my_hash = { 'a' => 'b', 'public_notes' => { '111' => 'note for 111', '222' => 'note for 222' } }
      subject.data = my_hash
      expect(subject.data).to eq my_hash
      expect(subject.data['public_notes']).to eq('111' => 'note for 111', '222' => 'note for 222')
    end
  end

  describe 'barcodes' do
    let(:array) { %w(a b c) }

    it 'is a serialized array' do
      expect(subject.barcodes).to eq([])
      subject.barcodes = array
      expect(subject.barcodes).to eq(array)
    end
  end

  describe 'notification_email_address' do
    before do
      subject.user = user
    end

    context 'for a normal request' do
      let(:user) { create(:non_sso_user) }

      it 'goes to the user email address' do
        expect(subject.notification_email_address).to eq user.email_address
      end
    end

    context 'for proxy requests' do
      let(:user) { create(:library_id_user) }

      before do
        allow(user).to receive_message_chain(:patron, :proxy_email_address).and_return('some@lists.stanford.edu')

        subject.proxy = true
      end

      it 'goes to the notice list for proxy requests' do
        expect(subject.notification_email_address).to eq 'some@lists.stanford.edu'
      end
    end

    context 'for proxy requests without a notification email' do
      let(:user) { create(:non_sso_user) }

      before do
        allow(user).to receive_message_chain(:patron, :proxy_email_address).and_return('')

        subject.proxy = true
      end

      it 'goes to the notice list for proxy requests' do
        expect(subject.notification_email_address).to eq user.email_address
      end
    end
  end

  describe '#default_pickup_destination' do
    it 'sets an origin specific default' do
      request = described_class.new(origin: 'LAW', origin_location: 'LAW-STACKS',
                                    bib_data: double(request_holdings: [build(:item, effective_location: build(:law_location))]))

      expect(request.default_pickup_destination).to eq 'LAW'
    end

    it 'falls back to a default location' do
      request = described_class.new(item_id: '12345', origin: 'ART', origin_location: 'ART-STACKS')

      expect(request.default_pickup_destination).to eq default_destination
    end
  end
end
