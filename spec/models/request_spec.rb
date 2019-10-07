# frozen_string_literal: true

require 'rails_helper'

describe Request do
  describe 'validations' do
    it 'requires the basic set of information to be present' do
      expect { described_class.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect do
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.create! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.create! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'requires that the requested barcodes exist in the holdings of the requested location' do
      stub_searchworks_api_json(build(:multiple_holdings))
      expect do
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          barcodes: %w(9999999 3610512345678)
        )
      end.to raise_error(
        ActiveRecord::RecordInvalid, 'Validation failed: A selected item is not located in the requested location'
      )
      described_class.create!(
        item_id: '1234',
        origin: 'GREEN',
        origin_location: 'STACKS',
        barcodes: %w(3610512345678)
      )
      expect(described_class.last.barcodes).to eq %w(3610512345678)
    end

    it 'requires that when a needed_date is provided it is not before today' do
      expect do
        described_class.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS',
          needed_date: Time.zone.today - 1.day
        )
      end.to raise_error(
        ActiveRecord::RecordInvalid, 'Validation failed: Needed on Date cannot be earlier than today'
      )
    end
  end

  describe 'scopes' do
    describe 'for_date' do
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

    describe 'for_create_date' do
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

    describe 'needed_date_desc' do
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

  describe 'commentable' do
    it 'mixin should be included' do
      expect(subject).to be_kind_of Commentable
    end

    describe 'item_commentable?' do
      describe 'with holdings' do
        before do
          allow(subject).to receive_messages(holdings: [{}])
          allow(subject).to receive_messages(holdings_object: double('mhld', mhld: [{}]))
        end

        it 'is true when the library is SAL-NEWARK or SPEC-COLL' do
          subject.origin = 'SAL-NEWARK'
          expect(subject).to be_item_commentable

          subject.origin = 'SPEC-COLL'
          expect(subject).to be_item_commentable
        end

        it 'is false when the library is not SAL-NEWARK or SPEC-COLL' do
          subject.origin = 'GREEN'
          expect(subject).not_to be_item_commentable
        end
      end

      describe 'without holdings' do
        before do
          allow(subject).to receive_messages(holdings: [{}])
          allow(subject).to receive_messages(holdings_object: double('mhld', mhld: nil))
        end

        it 'is false when the library is SAL-NEWARK or SPEC-COLL' do
          subject.origin = 'SAL-NEWARK'
          expect(subject).not_to be_item_commentable

          subject.origin = 'SPEC-COLL'
          expect(subject).not_to be_item_commentable
        end
      end
    end

    describe 'ad_hoc_item_commentable?' do
      context 'when no libraries are configured' do
        it 'is false' do
          expect(subject).not_to be_ad_hoc_item_commentable
        end
      end

      context 'when a library is configured' do
        before do
          libs = ['SAL-NEWARK']
          expect(SULRequests::Application.config).to receive(:ad_hoc_item_commentable_libraries).and_return(libs)
        end

        it 'is true for that library' do
          subject.origin = 'SAL-NEWARK'
          expect(subject).to be_ad_hoc_item_commentable
        end

        it 'is false for other libraries' do
          subject.origin = 'NOT-SAL-NEWARK'
          expect(subject).not_to be_ad_hoc_item_commentable
        end
      end
    end
  end

  describe 'requestable' do
    it { is_expected.not_to be_requestable_by_all }
    it { is_expected.not_to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }
    it { is_expected.not_to be_requires_additional_user_validation }
  end

  describe '#library_location' do
    it 'returns a library_location object' do
      expect(subject.library_location).to be_a LibraryLocation
    end
  end

  describe '#searchworks_item' do
    it 'returns a searchworks_item object' do
      expect(subject.searchworks_item).to be_a SearchworksItem
    end
  end

  describe '#holdings' do
    describe 'when persisted' do
      let(:subject) { create(:request_with_multiple_holdings, barcodes: ['3610512345678']) }

      it 'gets the holdings from the requested location by the persisted barcodes' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings.length).to eq 1
        expect(holdings.first.barcode).to eq '3610512345678'
        expect(holdings.first.callnumber).to eq 'ABC 123'
      end
    end

    describe 'when persisted with no selected barcode' do
      let(:subject) { create(:request_with_multiple_holdings, barcodes: []) }

      it 'gets all the holdings for the requested location' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings).to be_blank
      end
    end

    describe 'when not persisted' do
      let(:subject) { build(:request_with_multiple_holdings) }

      it 'gets all the holdings for the requested location' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings.length).to eq 3
        expect(holdings.first.barcode).to eq '3610512345678'
        expect(holdings.last.barcode).to eq '12345679'
      end
    end
  end

  describe '#all_holdings' do
    let(:subject) { build(:request_with_multiple_holdings, barcodes: ['3610512345678']) }

    it 'gets all the holdings for the requested location' do
      holdings = subject.all_holdings
      expect(holdings).to be_a Array
      expect(holdings.length).to eq 3
      expect(holdings.first.barcode).to eq '3610512345678'
      expect(holdings.last.barcode).to eq '12345679'
    end
  end

  describe '#requested_holdings' do
    let(:subject) { create(:request_with_multiple_holdings, barcodes: ['3610512345678']) }

    it 'gets the holdings from the requested location by the persisted barcodes' do
      holdings = subject.requested_holdings
      expect(holdings).to be_a Array
      expect(holdings.length).to eq 1
      expect(holdings.first.barcode).to eq '3610512345678'
      expect(holdings.first.callnumber).to eq 'ABC 123'
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
    it 'is nil when there is no configured item limit' do
      expect(subject.item_limit).to be_nil
    end

    it 'is 5 for items from SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject.item_limit).to eq 5
    end

    it 'is 5 for items from RUMSEYMAP' do
      subject.origin = 'RUMSEYMAP'
      expect(subject.item_limit).to eq 5
    end

    it 'is 20 for items from HV-ARCHIVE' do
      subject.origin = 'HV-ARCHIVE'
      expect(subject.item_limit).to eq 20
    end

    it 'is 5 for items from the PAGE-SP location' do
      subject.origin_location = 'PAGE-SP'
      expect(subject.item_limit).to eq 5
    end
  end

  describe 'nested attributes for' do
    describe 'users' do
      it 'handles webauth users (w/o emails) correctly' do
        User.create!(webauth: 'a-webauth-user')
        webauth_user = User.new(webauth: 'current-webauth-user')
        allow_any_instance_of(described_class).to receive_messages(user: webauth_user)
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
    it 'fetches the item title on object creation', allow_apis: true do
      described_class.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS')
      expect(described_class.last.item_title).to eq 'When do you need an antacid? : a burning question'
    end

    it 'does not fetch the title when it is already present' do
      described_class.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS', item_title: 'This title')
      expect(described_class.last.item_title).to eq 'This title'
    end
  end

  describe 'stored_or_fetched_item_title' do
    it 'returns the stored item title for persisted objects' do
      expect(create(:request).stored_or_fetched_item_title).to eq 'Title for Request 12345'
    end

    it 'returns the item title from the fetched searchworks record for non persisted objects' do
      allow_any_instance_of(described_class).to receive(:searchworks_item)
        .and_return(OpenStruct.new(title: 'A fetched title'))
      expect(described_class.new.stored_or_fetched_item_title).to eq 'A fetched title'
    end
  end

  describe '#delegate_request!' do
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
      let(:user) { create(:non_webauth_user) }

      it 'goes to the user email address' do
        expect(subject.notification_email_address).to eq user.email_address
      end
    end

    context 'for proxy requests' do
      let(:user) { create(:library_id_user) }
      let(:proxy_access) { double(email_address: 'some@lists.stanford.edu') }

      before do
        user.instance_variable_set(:@proxy_access, proxy_access)

        subject.proxy = true
      end

      it 'goes to the notice list for proxy requests' do
        expect(subject.notification_email_address).to eq proxy_access.email_address
      end
    end

    context 'for proxy requests without a notification email' do
      let(:user) { create(:non_webauth_user) }
      let(:proxy_access) { double(email_address: '') }

      before do
        user.instance_variable_set(:@proxy_access, proxy_access)

        subject.proxy = true
      end

      it 'goes to the notice list for proxy requests' do
        expect(subject.notification_email_address).to eq user.email_address
      end
    end
  end

  describe 'send_confirmation!' do
    let(:subject) { create(:page, user: create(:webauth_user)) }

    it 'returns true (other classes can implement confirmation if they want it)' do
      expect do
        subject.send_confirmation!
      end.not_to change { ConfirmationMailer.deliveries.count }
      expect(subject.send_confirmation!).to be true
    end
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:subject) { create(:page, user: create(:library_id_user)) }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to change { ApprovalStatusMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:page, user: create(:webauth_user)) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to change { ApprovalStatusMailer.deliveries.count }.by(1)
      end
    end
  end

  describe '#check_remote_ip?' do
    it 'mediated pages (that are not Hopkins)' do
      expect(create(:mediated_page).check_remote_ip?).to be true
    end

    it 'Hopkins mediated page' do
      expect(create(:mediated_page, origin: 'HOPKINS', destination: 'GREEN').check_remote_ip?).to be false
    end

    it 'non-mediated pages are false' do
      expect(create(:page).check_remote_ip?).to be false
    end
  end

  describe 'mediateable_origins' do
    before do
      create(:mediated_page)
      create(:hoover_archive_mediated_page)
      create(:hopkins_mediated_page)
    end

    it 'returns the subset of origin codes that are configured and mediated pages that exist in the database' do
      expect(described_class.mediateable_origins).to eq %w(HOPKINS HV-ARCHIVE SPEC-COLL)
    end
  end

  describe '#submit!' do
    it 'submits the request to Symphony' do
      expect(SubmitSymphonyRequestJob).to receive(:perform_later)
      subject.submit!
    end
  end

  describe '#send_to_symphony!' do
    it 'submits the request to Symphony' do
      expect(SubmitSymphonyRequestJob).to receive(:perform_later).with(subject.id, a: 1)
      subject.send_to_symphony_later! a: 1
    end
  end

  describe '#appears_in_myaccount?' do
    context 'with non-webauth users' do
      it 'is disabled' do
        subject.user = create(:library_id_user)
        expect(subject.appears_in_myaccount?).to be false
      end
    end

    context 'for webauth users' do
      it 'is enabled' do
        subject.user = create(:webauth_user)
        expect(subject.appears_in_myaccount?).to be true
      end
    end
  end

  describe '#symphony_request' do
    it 'provides access to the raw request object' do
      expect(subject.symphony_request).to be_a SubmitSymphonyRequestJob::Command
    end
  end

  describe '#merge_symphony_response_data' do
    before do
      subject.symphony_response_data = FactoryBot.build(:symphony_scan_with_multiple_items)
    end

    it 'uses any new request-level data' do
      subject.merge_symphony_response_data req_type: 'SCAN',
                                           usererr_code: 'USERBLOCKED',
                                           usererr_text: 'User is Blocked'

      expect(subject.symphony_response.usererr_code).to eq 'USERBLOCKED'
      expect(subject.symphony_response.usererr_text).to eq 'User is Blocked'
    end

    it 'preserves old item-level data' do
      subject.merge_symphony_response_data req_type: 'SCAN',
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
                                           ]

      item_status = subject.symphony_response.items_by_barcode
      expect(item_status['987654321']).to be_present
      expect(item_status['987654321']['msgcode']).to eq '209'

      expect(item_status['12345678901234z']).to be_present
      expect(item_status['12345678901234z']['msgcode']).to eq '209'

      expect(item_status['36105212920537']).to be_present
      expect(item_status['36105212920537']['msgcode']).to eq 'S001'
    end
  end
end
