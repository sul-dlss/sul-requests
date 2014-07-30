require 'spec_helper'

describe Admin::FieldsController, type: :controller do
   
  describe "GET #index" do 
    
    it "populates an array of fields" do
      field = FactoryGirl.build(:field)
      #assigns(:field).should eq(field) # doesn't work
      field['field_name'].should eq('ckey')
    end
    
    it "renders the :index view" do 
       controller.request.env['WEBAUTH_USER'] = 'foo' # requires authentication
       get :index 
       response.should render_template :index 
    end 
    
  end 
  
  # Note no show action 

   
  
end 
  
