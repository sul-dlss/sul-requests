class Admin::FieldsController < ApplicationController
  
  before_filter :is_authenticated?
  
  def index
    #@fields = Field.find(:all,  :order => 'field_order')
    @fields = Field.order('field_order').all
    #puts "====== fields is " + @fields.inspect
  end

  def show
    @field = Field.find(params[:id])
  end

  def new
    @field = Field.new
  end

  def create
    @field = Field.new(params[:field])
    if @field.save
      redirect_to admin_fields_path
    else
      render :action => 'new'
    end
  end

  def edit
    @field = Field.find(params[:id])
  end

  def update
    @field = Field.find(params[:id])
    if @field.update_attributes(params[:field])
      redirect_to admin_fields_path 
    else
      render :action => 'edit' 
    end
    
  end
  
  def destroy
    Field.find(params[:id]).destroy
    redirect_to admin_fields_path
  end

end
