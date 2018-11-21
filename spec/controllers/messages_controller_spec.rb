# frozen_string_literal: true

require 'rails_helper'

describe MessagesController, type: :controller do
  before do
    allow(controller).to receive_messages(current_user: user)
  end

  let(:user) { create(:superadmin_user) }

  let(:required_attributes) do
    { library: 'ARS', request_type: 'page' }
  end

  let(:valid_attributes) do
    required_attributes.merge(start_at: Time.zone.now, end_at: Time.zone.now + 1.day)
  end

  let(:invalid_attributes) do
    { library: '', request_type: nil }
  end

  let(:valid_session) { {} }

  describe 'GET #index' do
    it 'assigns all messages as @messages' do
      message = Message.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:messages)).to eq([message])
    end
  end

  describe 'GET #new' do
    it 'assigns a new message as @message' do
      get :new, required_attributes, valid_session
      expect(assigns(:message)).to be_a_new(Message)
    end

    it 'pulls library and request types from parameters' do
      get :new, { library: 'ARS', request_type: 'page' }, valid_session
      message = assigns(:message)
      expect(message.library).to eq 'ARS'
      expect(message.request_type).to eq 'page'
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested message as @message' do
      message = Message.create! valid_attributes
      get :edit, { id: message.to_param }, valid_session
      expect(assigns(:message)).to eq(message)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Message' do
        expect do
          post :create, { message: valid_attributes }, valid_session
        end.to change(Message, :count).by(1)
      end

      it 'assigns a newly created message as @message' do
        post :create, { message: valid_attributes }, valid_session
        expect(assigns(:message)).to be_a(Message)
        expect(assigns(:message)).to be_persisted
      end

      it 'redirects to the created message' do
        post :create, { message: valid_attributes }, valid_session
        expect(response).to redirect_to messages_url
      end
    end

    context 'with invalid attributes' do
      it 'assigns a newly created but unsaved message as @message' do
        post :create, { message: invalid_attributes }, valid_session
        expect(assigns(:message)).to be_a_new(Message)
      end

      it "re-renders the 'new' template" do
        post :create, { message: invalid_attributes }, valid_session
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { start_at: Time.zone.now - 1.day }
      end

      it 'updates the requested message' do
        message = Message.create! valid_attributes
        put :update, { id: message.to_param, message: new_attributes }, valid_session
        message.reload
        expect(message.start_at).to be < Time.zone.now
      end

      it 'assigns the requested message as @message' do
        message = Message.create! valid_attributes
        put :update, { id: message.to_param, message: valid_attributes }, valid_session
        expect(assigns(:message)).to eq Message.last
      end

      it 'redirects to the message' do
        message = Message.create! valid_attributes
        put :update, { id: message.to_param, message: valid_attributes }, valid_session
        expect(response).to redirect_to messages_url
      end
    end

    context 'with invalid attributes' do
      it 'assigns the requested message as @message' do
        message = Message.create! valid_attributes
        put :update, { id: message.to_param, message: invalid_attributes }, valid_session
        expect(assigns(:message)).to eq(message)
      end

      it "re-renders the 'new' template" do
        message = Message.create! valid_attributes
        put :update, { id: message.to_param, message: invalid_attributes }, valid_session
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested message' do
      message = Message.create! valid_attributes
      expect do
        delete :destroy, { id: message.to_param }, valid_session
      end.to change(Message, :count).by(-1)
    end

    it 'redirects to the messages list' do
      message = Message.create! valid_attributes
      delete :destroy, { id: message.to_param }, valid_session
      expect(response).to redirect_to(messages_url)
    end
  end
end
