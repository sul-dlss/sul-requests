class Admin::MessagesController < ApplicationController
  
  before_filter :is_authenticated?
  
  def index
    @messages = Message.find(:all,  :order => 'msg_number')
  end
  
  def show
    @message = Message.find(params[:id])
  end  
  
  def create
    @message = Message.new(params[:message])
    if @message.save
      redirect_to admin_messages_path
    else
      render :action => 'new'
    end
  end  

  def edit
    @message = Message.find(params[:id])
  end

  def new
     @message = Message.new
 end
 
  def update
    @message = Message.find(params[:id])
    if @message.update_attributes(params[:message])
      redirect_to admin_messages_path 
    else
      render :action => 'edit' 
    end
  end
  
  
  def destroy
    Message.find(params[:id]).destroy
    redirect_to admin_messages_path
  end  
  
end
