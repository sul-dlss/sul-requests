class FormsController < ApplicationController
  def index
  end

  def new
    @form = Form.new 
    @form.form_id = (params[:form_id])
    @form.title = (params[:title])
    @form.heading = (params[:heading])
    @form.before_fields = (params[:before_fields])
    @form.after_fields = (params[:after_fields])
  end
  
  def create
    @form = Form.new(params[:form])
    # Not sure where to send user after form is saved
    if @form.save
      redirect_to forms_path
    end
  end
  
  def show
      @form = Form.find(params[:id])
  end


  
  def index
      @forms = Form.find(:all)
  end




end
