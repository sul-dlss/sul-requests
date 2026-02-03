# frozen_string_literal: true

##
# Allow administrators to add special broadcast messages to request forms
class MessagesController < ApplicationController
  load_and_authorize_resource

  # GET /messages
  # GET /messages.json
  def index
  end

  # GET /messages/new
  def new
    @message.library = params.require(:library)
    @message.request_type = params.require(:request_type)
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(message_params)

    respond_to do |format|
      if @message.save
        format.html { redirect_to messages_url, notice: 'Message was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /messages/1
  # PATCH/PUT /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to messages_url, notice: 'Message was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def message_params
    params.expect(message: [:text, :start_at, :end_at, :library, :request_type])
  end
end
