# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedbackMailer do
  describe 'submit_feedback' do
    describe 'with all fields' do
      let(:ip) { '123.43.54.123' }
      let(:params) do
        {
          name: 'Mildred Turner ',
          to: 'test@test.com',
          user_agent: 'agent #1',
          viewport: 'width:100 height:50'
        }
      end
      let(:mail) { described_class.submit_feedback(params, ip) }

      it 'has the correct to field' do
        expect(mail.to).to eq ['yolo@example.com']
      end

      it 'has the correct subject' do
        expect(mail.subject).to eq 'Feedback from Requests'
      end

      it 'has the correct from field' do
        expect(mail.from).to eq ['feedback@requests.stanford.edu']
      end

      it 'has the correct reply to field' do
        expect(mail.reply_to).to eq ['yolo@example.com']
      end

      it 'has the right email' do
        expect(mail.body).to have_content 'Name: Mildred Turner'
      end

      it 'has the right name' do
        expect(mail.body).to have_content 'Email: test@test.com'
      end

      it 'has the right host' do
        expect(mail.body).to have_content 'Host: foo.example.com'
      end

      it 'has the right IP' do
        expect(mail.body).to have_content '123.43.54.123'
      end

      it 'has the user_agent' do
        expect(mail.body).to have_content 'agent #1'
      end
    end

    describe 'without name and email' do
      let(:ip) { '123.43.54.123' }
      let(:params) { {} }
      let(:mail) { described_class.submit_feedback(params, ip) }

      it 'has the right email' do
        expect(mail.body).to have_content 'Name: No name given'
      end

      it 'has the right name' do
        expect(mail.body).to have_content 'Email: No email given'
      end
    end
  end
end
