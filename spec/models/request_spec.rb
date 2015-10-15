require 'rails_helper'

describe Request do
  describe 'validations' do
    it 'should require the basic set of information to be present' do
      expect(-> { Request.create! }).to raise_error(ActiveRecord::RecordInvalid)
      expect(-> { Request.create!(item_id: '1234', origin: 'GREEN') }).to raise_error(ActiveRecord::RecordInvalid)
      expect(-> { Request.create! }).to raise_error(ActiveRecord::RecordInvalid)
      expect(-> { Request.create! }).to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'requires that the requested barcodes exist in the holdings of the requested location' do
      stub_searchworks_api_json(build(:multiple_holdings))
      expect(
        lambda do
          Request.create!(
            item_id: '1234',
            origin: 'GREEN',
            origin_location: 'STACKS',
            barcodes: %w(9999999 3610512345678)
          )
        end
      ).to raise_error(
        ActiveRecord::RecordInvalid, 'Validation failed: A selected item is not located in the requested location'
      )
      Request.create!(
        item_id: '1234',
        origin: 'GREEN',
        origin_location: 'STACKS',
        barcodes: %w(3610512345678)
      )
      expect(Request.last.barcodes).to eq %w(3610512345678)
    end

    it 'requires that when a needed_date is provided it is not before today' do
      expect(
        lambda do
          Request.create!(
            item_id: '1234',
            origin: 'GREEN',
            origin_location: 'STACKS',
            needed_date: Time.zone.today - 1.day
          )
        end
      ).to raise_error(
        ActiveRecord::RecordInvalid, 'Validation failed: Date cannot be earlier than today'
      )
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
          expect(subject).to_not be_item_commentable
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
  end

  describe 'requestable' do
    it { is_expected.not_to be_requestable_by_all }
    it { is_expected.not_to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }
  end

  describe '#library_location' do
    it 'should return a library_location object' do
      expect(subject.library_location).to be_a LibraryLocation
    end
  end

  describe '#searchworks_item' do
    it 'should return a searchworks_item object' do
      expect(subject.searchworks_item).to be_a SearchworksItem
    end
  end

  describe '#holdings' do
    describe 'when persisted' do
      let(:subject) { create(:request_with_multiple_holdings, barcodes: ['3610512345678']) }
      it 'should get the holdings from the requested location by the persisted barcodes' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings.length).to eq 1
        expect(holdings.first.barcode).to eq '3610512345678'
        expect(holdings.first.callnumber).to eq 'ABC 123'
      end
    end

    describe 'when persisted with no selected barcode' do
      let(:subject) { create(:request_with_multiple_holdings, barcodes: []) }
      it 'should get all the holdings for the requested location' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings).to be_blank
      end
    end

    describe 'when not persisted' do
      let(:subject) { build(:request_with_multiple_holdings) }
      it 'should get all the holdings for the requested location' do
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
    it 'should get all the holdings for the requested location' do
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
    it 'is nil for the base request class' do
      expect(subject.item_limit).to be_nil
    end
  end

  describe 'nested attributes for' do
    describe 'users' do
      it 'should handle webauth users (w/o emails) correctly' do
        User.create!(webauth: 'a-webauth-user')
        webauth_user = User.new(webauth: 'current-webauth-user')
        allow_any_instance_of(Request).to receive_messages(user: webauth_user)
        Request.create!(
          item_id: '1234',
          origin: 'GREEN',
          origin_location: 'STACKS'
        )
        expect(Request.last.user).to eq User.last
      end

      it 'should create new users' do
        expect(User.find_by_email('jstanford@stanford.edu')).to be_nil
        Request.create(
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

      it 'should not duplicate users email addresses' do
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 0
        User.create(email: 'jstanford@stanford.edu')
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 1
        Request.create!(
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

      it 'should update email users name' do
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 0
        User.create(email: 'jstanford@stanford.edu', name: 'J. Stanford')
        expect(User.where(email: 'jstanford@stanford.edu').length).to eq 1
        Request.create!(
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

      it 'should not duplicate library ids' do
        expect(User.where(library_id: '12345').length).to eq 0
        User.create(library_id: '12345')
        expect(User.where(library_id: '12345').length).to eq 1
        Request.create!(
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
    it 'should fetch the item title on object creation', allow_apis: true do
      Request.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS')
      expect(Request.last.item_title).to eq 'When do you need an antacid? : a burning question'
    end

    it 'should not fetch the title when it is already present' do
      Request.create!(item_id: '2824966', origin: 'GREEN', origin_location: 'STACKS', item_title: 'This title')
      expect(Request.last.item_title).to eq 'This title'
    end
  end

  describe 'stored_or_fetched_item_title' do
    it 'should return the stored item title for persisted objects' do
      expect(create(:request).stored_or_fetched_item_title).to eq 'Title for Request 12345'
    end
    it 'should return the item title from the fetched searchworks record for non persisted objects' do
      allow_any_instance_of(Request).to receive(:searchworks_item).and_return(OpenStruct.new(title: 'A fetched title'))
      expect(Request.new.stored_or_fetched_item_title).to eq 'A fetched title'
    end
  end

  describe '#delegate_request!' do
    it 'should delegate to a mediated page if it is mediateable' do
      allow(subject).to receive_messages(mediateable?: true)
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'MediatedPage'
    end

    it 'should delegate to a hold recall if it is hold recallable' do
      allow(subject).to receive_messages(hold_recallable?: true)
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'HoldRecall'
    end

    it 'should delegate to a page request otherwise' do
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'Page'
    end
  end

  describe '#data' do
    let(:data_hash) { { 'a' => 'a', 'b' => 'b' } }
    it 'should be a serialized hash' do
      expect(subject.data).to eq({})
      subject.data = data_hash
      expect(subject.data).to eq data_hash
    end
  end

  describe 'barcodes' do
    let(:array) { %w(a b c) }
    it 'should be a serialized array' do
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
    describe 'for library id users' do
      it 'does not send a confirmation email' do
        subject.user = create(:library_id_user)
        expect(
          -> { subject.send_confirmation! }
        ).to_not change { ConfirmationMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:page, user: create(:webauth_user)) }
      it 'sends a confirmation email' do
        expect(
          -> { subject.send_confirmation! }
        ).to change { ConfirmationMailer.deliveries.count }.by(1)
      end
    end
  end

  describe 'mediateable_origins' do
    before do
      create(:mediated_page)
      create(:hoover_mediated_page)
      create(:hopkins_mediated_page)
    end
    it 'should return the subset of origin codes that are configured and mediated pages that exist in the database' do
      expect(Request.mediateable_origins).to eq %w(HOPKINS HOOVER SPEC-COLL)
    end
  end

  describe '#submit!' do
    it 'submits the request to Symphony' do
      expect(SubmitSymphonyRequestJob).to receive(:perform_now)
      subject.submit!
    end
  end

  describe '#send_to_symphony!' do
    it 'submits the request to Symphony' do
      expect(SubmitSymphonyRequestJob).to receive(:perform_now).with(subject, a: 1)
      subject.send_to_symphony! a: 1
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
      subject.symphony_response_data = FactoryGirl.build(:symphony_scan_with_multiple_items)
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
