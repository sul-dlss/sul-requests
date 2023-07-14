# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request do
  let(:items) { [] }
  let(:bib_data) { double(:bib_data, title: 'Test title', request_holdings: items) }

  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(bib_data)
  end

  describe 'validations' do
    it 'requires the basic set of information to be present' do
      expect do
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'when barcodes are provided' do
      before do
        stub_bib_data_json(build(:multiple_holdings))
      end

      let(:items) { [double('item', barcode: '3610512345678')] }

      let(:create_request) do
        described_class.create!(
          item_id: '1234',
          origin: 'SAL3',
          origin_location: 'STACKS',
          barcodes:
        )
      end

      context 'when one of the requested barcodes does not exist in the ILS' do
        let(:barcodes) { %w(9999999 3610512345678) }

        it 'fails to validate' do
          expect { create_request }.to raise_error(
            ActiveRecord::RecordInvalid, 'Validation failed: A selected item is not located in the requested location'
          )
        end
      end

      context 'when the barcodes exists in the ILS' do
        let(:barcodes) { %w(3610512345678) }

        it 'passes validation' do
          create_request
          expect(described_class.last.barcodes).to eq %w(3610512345678)
        end
      end
    end

    context 'when a needed_date is provided and it is before today' do
      let(:create_request) do
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          needed_date: Time.zone.today - 1.day
        )
      end

      it 'fails validation' do
        expect { create_request }.to raise_error(
          ActiveRecord::RecordInvalid, 'Validation failed: Needed on Date cannot be earlier than today'
        )
      end
    end

    context 'when the item is scannable only' do
      let(:create_request) do
        described_class.create!(
          item_id: '123456',
          origin: 'SAL',
          origin_location: 'SAL-TEMP'
        )
      end
      let(:items) do
        # This is just used for Searchworks integration
        [double(:item, type: 'NONCIRC', code: 'SAL-TEMP', barcode: '12345678')]
      end

      it 'fails validation' do
        pending('FOLIO does not have any non-circulating, scannable items') if Settings.ils.bib_model == 'Folio::Instance'

        expect { create_request }.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: This item is for in-library use and not available for Request & pickup.'
        )
      end
    end
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

  describe 'requestable' do
    it { is_expected.not_to be_requestable_with_name_email }
    it { is_expected.not_to be_requestable_with_library_id }
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

  describe '#item_limit' do
    subject { request.item_limit }

    let(:request) { described_class.new }

    context 'when there is no configured item limit' do
      it { is_expected.to be_nil }
    end

    context 'when the origin is SPEC-COLL' do
      before do
        request.origin = 'SPEC-COLL'
      end

      it { is_expected.to eq 5 }
    end

    context 'when the origin is RUMSEYMAP' do
      before do
        request.origin = 'RUMSEYMAP'
      end

      it { is_expected.to eq 5 }
    end

    context 'when the origin is PAGE-SP' do
      before do
        request.origin_location = 'PAGE-SP'
      end

      it { is_expected.to eq 5 }
    end
  end

  describe 'nested attributes for' do
    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: '12345').and_return(
        instance_double(Symphony::Patron, exists?: true)
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
          origin_location: 'STACKS'
        )
        expect(described_class.last.user).to eq User.last
      end

      it 'creates new users' do
        expect(User.find_by_email('jstanford@stanford.edu')).to be_nil
        described_class.create(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
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
          origin_location: 'STACKS',
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
          origin_location: 'STACKS',
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
          origin_location: 'STACKS',
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
            origin_location: 'STACKS',
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
          origin_location: 'STACKS',
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
        described_class.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS')
        expect(described_class.last.item_title).to eq 'When do you need an antacid? : a burning question'
      end
    end

    context 'when the title is present' do
      it 'does not fetch the title' do
        described_class.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS', item_title: 'This title')
        expect(described_class.last.item_title).to eq 'This title'
      end
    end

    it 'returns the stored item title for persisted objects' do
      expect(create(:request).item_title).to eq 'Title for Request 123456'
    end

    it 'returns the item title from the fetched searchworks record' do
      allow_any_instance_of(described_class).to receive(:bib_data)
        .and_return(instance_double(described_class.bib_model_class, title: 'A fetched title'))
      expect(described_class.new.item_title).to eq 'A fetched title'
    end
  end

  describe '#delegate_request!' do
    before do
      stub_bib_data_json(build(:multiple_holdings))
      subject.update(origin: 'SAL3', origin_location: 'STACKS')
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

  describe 'send_approval_status!' do
    subject(:request) { create(:page, user:) }

    let(:user) {}

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: user.library_id).and_return(
        instance_double(Symphony::Patron, exists?: true, email: '')
      )
    end

    describe 'for library id users' do
      let(:user) { create(:library_id_user) }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to have_enqueued_mail
      end
    end

    describe 'for everybody else' do
      let(:user) { create(:sso_user) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to have_enqueued_mail(RequestStatusMailer)
      end
    end
  end

  describe '#check_remote_ip?' do
    it 'mediated pages' do
      expect(create(:mediated_page).check_remote_ip?).to be true
    end

    it 'non-mediated pages are false' do
      expect(create(:page)).not_to be_check_remote_ip
    end
  end

  describe 'mediateable_origins' do
    before do
      create(:mediated_page)
      create(:page_mp_mediated_page)
    end

    it 'returns the subset of origin codes that are configured and mediated pages that exist in the database' do
      expect(described_class.mediateable_origins.to_h.keys).to eq %w(ART PAGE-MP)
    end
  end

  describe '#submit!' do
    it 'submits the request to Symphony' do
      expect(described_class.ils_job_class).to receive(:perform_later)
      subject.submit!
    end
  end

  describe '#send_to_ils!' do
    it 'submits the request to Symphony' do
      expect(described_class.ils_job_class).to receive(:perform_later).with(subject.id, { a: 1 })
      subject.send_to_ils_later! a: 1
    end
  end

  describe '#ils_request_command' do
    it 'provides access to the raw request object' do
      expect(subject.ils_request_command).to be_a described_class.ils_job_class.command
    end
  end

  describe '#merge_ils_response_data' do
    before do
      subject.symphony_response_data = build(:symphony_scan_with_multiple_items)
    end

    it 'uses any new request-level data' do
      subject.merge_ils_response_data SymphonyResponse.new(req_type: 'SCAN',
                                                           usererr_code: 'USERBLOCKED',
                                                           usererr_text: 'User is Blocked')

      expect(subject.ils_response.usererr_code).to eq 'USERBLOCKED'
      expect(subject.ils_response.usererr_text).to eq 'User is Blocked'
    end

    it 'preserves old item-level data' do
      subject.merge_ils_response_data SymphonyResponse.new(req_type: 'SCAN',
                                                           requested_items: [
                                                             {
                                                               'barcode' => '987654321',
                                                               'msgcode' => '209',
                                                               'text' => 'Hold placed'
                                                             },
                                                             {
                                                               'barcode' => '12345678901234z',
                                                               'msgcode' => '209',
                                                               'text' => 'Hold placed'
                                                             }
                                                           ])

      item_status = subject.ils_response.items_by_barcode
      expect(item_status['987654321']).to be_present
      expect(item_status['987654321']['msgcode']).to eq '209'

      expect(item_status['12345678901234z']).to be_present
      expect(item_status['12345678901234z']['msgcode']).to eq '209'

      expect(item_status['36105212920537']).to be_present
      expect(item_status['36105212920537']['msgcode']).to eq 'S001'
    end
  end

  describe '#default_pickup_library' do
    it 'sets an origin specific default' do
      request = described_class.new(origin: 'LAW', origin_location: 'STACKS',
                                    bib_data: double(request_holdings: [build(:item, effective_location: build(:law_location))]))

      expect(request.default_pickup_library).to eq 'LAW'
    end

    it 'sets an origin location specific default' do
      request = described_class.new(origin: 'EAST-ASIA', origin_location: 'EAL-SETS',
                                    bib_data: double(request_holdings: [build(:item, effective_location: build(:eal_sets_location))]))

      expect(request.default_pickup_library).to eq 'EAST-ASIA'
    end

    it 'falls back to a default location' do
      request = described_class.new(origin: 'ART', origin_location: 'STACKS')

      expect(request.default_pickup_library).to eq 'GREEN'
    end
  end
end
