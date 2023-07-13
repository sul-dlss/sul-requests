# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlWaitlistMailer do
  let(:patron_key) { 42 }
  let(:patron) do
    instance_double(Symphony::Patron, email: 'someone@example.com')
  end
  let(:hold_record_key) { 'key' }

  before do
    allow(Symphony::Patron).to receive(:find_by).with(patron_key:).and_return(patron)
    allow(Symphony::HoldRecord).to receive(:find).with(hold_record_key).and_return(hold_record)
  end

  describe '.youre_up' do
    subject(:mail) { described_class.youre_up(hold_record_key, circ_record_key) }

    let(:hold_record_key) { 'key' }

    let(:hold_record) do
      Symphony::HoldRecord.new({
        key: 'xyz',
        fields: {
          comment: "CDL;druid;12345:1:1:1;#{checkout_date.to_i};NEXT_UP",
          patron: {
            key: patron_key
          },
          item: {
            fields: {
              bib: {
                fields: {
                  title: 'Book: A Book'
                }
              }
            }
          }
        }
      }.with_indifferent_access)
    end
    let(:checkout_date) { Time.zone.parse('2020-09-15T11:12:13') }
    let(:circ_record) do
      instance_double(Symphony::CircRecord, due_date: Time.zone.parse('2020-09-16T01:02:03'),
                                            checkout_date:)
    end
    let(:circ_record_key) { 'circ_record_key' }

    before do
      allow(hold_record).to receive(:patron).and_return(patron)
      allow(Symphony::CircRecord).to receive(:find).with(circ_record_key).and_return(circ_record)
    end

    describe 'to' do
      it 'is the patron' do
        expect(mail.to).to eq ['someone@example.com']
      end
    end

    describe 'subject' do
      it 'is the default' do
        expect(mail.subject).to eq 'Ready for checkout: Book: A Book'
      end
    end

    describe 'body' do
      subject(:body) { mail.body.to_s }

      it { is_expected.to include '"Book: A Book" is available' }
      it { is_expected.to include 'We are holding this item for you until  1:02a PDT' }
    end
  end

  describe '.hold_expired' do
    subject(:mail) { described_class.hold_expired(hold_record_key) }

    let(:hold_record) do
      Symphony::HoldRecord.new({
        key: 'xyz',
        fields: {
          comment: "CDL;druid;12345:1:1:1;#{Time.zone.parse('2020-09-15T11:12:13').to_i};NEXT_UP",
          patron: {
            key: patron_key
          },
          item: {
            fields: {
              bib: {
                fields: {
                  title: 'Book: A Book'
                }
              }
            }
          }
        }
      }.with_indifferent_access)
    end

    describe 'to' do
      it 'is the patron' do
        expect(mail.to).to eq ['someone@example.com']
      end
    end

    describe 'subject' do
      it 'is the default' do
        expect(mail.subject).to eq 'Hold expired for: Book: A Book'
      end
    end

    describe 'body' do
      subject(:body) { mail.body.to_s }

      it { is_expected.to include '"Book: A Book" was on hold for you until 11:42a PDT' }
    end
  end

  describe '.on_waitlist' do
    subject(:mail) { described_class.on_waitlist(hold_record_key) }

    let(:hold_record) do
      Symphony::HoldRecord.new({
        key: 'xyz',
        fields: {
          comment: 'CDL;druid',
          queuePosition: 5,
          patron: {
            key: patron_key
          },
          item: {
            fields: {
              bib: {
                fields: {
                  title: 'Book: A Book'
                }
              }
            }
          }
        }
      }.with_indifferent_access)
    end

    describe 'to' do
      it 'is the patron' do
        expect(mail.to).to eq ['someone@example.com']
      end
    end

    describe 'subject' do
      it 'is the default' do
        expect(mail.subject).to eq 'Added to waitlist for: Book: A Book'
      end
    end

    describe 'body' do
      subject(:body) { mail.body.to_s }

      it { is_expected.to include 'added to the waitlist for "Book: A Book"' }
      it { is_expected.to include 'You are 4th in line.' }
    end
  end
end
