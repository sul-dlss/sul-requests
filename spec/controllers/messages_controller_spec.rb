# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessagesController do
  before do
    allow(controller).to receive_messages(current_user: user)
  end

  let(:user) { create(:superadmin_user) }

  let(:required_attributes) do
    { library: 'ARS', request_type: 'page' }
  end

  let(:valid_attributes) do
    required_attributes.merge(start_at: Time.zone.now, end_at: 1.day.from_now)
  end

  let(:invalid_attributes) do
    { library: '', request_type: nil }
  end

  let(:valid_session) { {} }

  describe 'GET #index' do
    it 'assigns all messages as @messages' do
      message = Message.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(assigns(:messages)).to eq([message])
    end
  end

  describe 'GET #new' do
    it 'assigns a new message as @message' do
      get :new, params: required_attributes, session: valid_session
      expect(assigns(:message)).to be_a_new(Message)
    end

    it 'pulls library and request types from parameters' do
      get :new, params: { library: 'ARS', request_type: 'page' }, session: valid_session
      message = assigns(:message)
      expect(message.library).to eq 'ARS'
      expect(message.request_type).to eq 'page'
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested message as @message' do
      message = Message.create! valid_attributes
      get :edit, params: { id: message.to_param }, session: valid_session
      expect(assigns(:message)).to eq(message)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Message' do
        expect do
          post :create, params: { message: valid_attributes }, session: valid_session
        end.to change(Message, :count).by(1)
      end

      it 'assigns a newly created message as @message' do
        post :create, params: { message: valid_attributes }, session: valid_session
        expect(assigns(:message)).to be_a(Message)
        expect(assigns(:message)).to be_persisted
      end

      it 'redirects to the created message' do
        post :create, params: { message: valid_attributes }, session: valid_session
        expect(response).to redirect_to messages_url
      end
    end

    context 'with invalid attributes' do
      it 'assigns a newly created but unsaved message as @message' do
        post :create, params: { message: invalid_attributes }, session: valid_session
        expect(assigns(:message)).to be_a_new(Message)
      end

      it "re-renders the 'new' template" do
        post :create, params: { message: invalid_attributes }, session: valid_session
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { start_at: 1.day.ago }
      end

      it 'updates the requested message' do
        message = Message.create! valid_attributes
        put :update, params: { id: message.to_param, message: new_attributes }, session: valid_session
        message.reload
        expect(message.start_at).to be < Time.zone.now
      end

      it 'assigns the requested message as @message' do
        message = Message.create! valid_attributes
        put :update, params: { id: message.to_param, message: valid_attributes }, session: valid_session
        expect(assigns(:message)).to eq Message.last
      end

      it 'redirects to the message' do
        message = Message.create! valid_attributes
        put :update, params: { id: message.to_param, message: valid_attributes }, session: valid_session
        expect(response).to redirect_to messages_url
      end
    end

    context 'with invalid attributes' do
      it 'assigns the requested message as @message' do
        message = Message.create! valid_attributes
        put :update, params: { id: message.to_param, message: invalid_attributes }, session: valid_session
        expect(assigns(:message)).to eq(message)
      end

      it "re-renders the 'new' template" do
        message = Message.create! valid_attributes
        put :update, params: { id: message.to_param, message: invalid_attributes }, session: valid_session
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested message' do
      message = Message.create! valid_attributes
      expect do
        delete :destroy, params: { id: message.to_param }, session: valid_session
      end.to change(Message, :count).by(-1)
    end

    it 'redirects to the messages list' do
      message = Message.create! valid_attributes
      delete :destroy, params: { id: message.to_param }, session: valid_session
      expect(response).to redirect_to(messages_url)
    end
  end
end
