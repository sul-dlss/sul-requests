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
            barcodes: %w(9999999 12345678)
          )
        end
      ).to raise_error(
        ActiveRecord::RecordInvalid, 'Validation failed: A selected item is not located in the requested location'
      )
      Request.create!(
        item_id: '1234',
        origin: 'GREEN',
        origin_location: 'STACKS',
        barcodes: %w(12345678)
      )
      expect(Request.last.barcodes).to eq %w(12345678)
    end
  end

  describe '#scannable?' do
    it 'should be scannable if it is a SAL3 item in the STACKS location' do
      subject.origin = 'SAL3'
      subject.origin_location = 'STACKS'
      expect(subject).to be_scannable
    end

    it 'should not be scannable if it is not in the corect location and library' do
      expect(subject).to_not be_scannable
    end
  end

  describe '#commentable?' do
    it 'should be false' do
      expect(subject).to_not be_commentable
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
      let(:subject) { create(:request_with_multiple_holdings, barcodes: ['12345678']) }
      it 'should get the holdings from the requested location by the persisted barcodes' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings.length).to eq 1
        expect(holdings.first.barcode).to eq '12345678'
        expect(holdings.first.callnumber).to eq 'ABC 123'
      end
    end

    describe 'when not persisted' do
      let(:subject) { build(:request_with_multiple_holdings) }
      it 'should get all the holdings for the requested location' do
        holdings = subject.holdings
        expect(holdings).to be_a Array
        expect(holdings.length).to eq 3
        expect(holdings.first.barcode).to eq '12345678'
        expect(holdings.last.barcode).to eq '12345679'
      end
    end
  end

  describe '#data_to_email_s' do
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
    end
  end

  describe 'item_title' do
    it 'should fetch the item title on object creation' do
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

    it 'should delegate to a page request otherwise' do
      expect(subject.type).to be_nil
      subject.delegate_request!
      expect(subject.type).to eq 'Page'
    end
  end

  describe '#data' do
    let(:data_hash) { { a: :a, b: :b } }
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
end
