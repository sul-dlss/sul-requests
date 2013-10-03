require 'spec_helper'

describe Field do
  it "has a valid factory" do
    FactoryGirl.create(:field).should be_valid
  end
  
  it "is invalid without a field_name" do
    FactoryGirl.build(:field, field_name: nil).should_not be_valid   
  end
  
  it "is invalid without a field label" do
    FactoryGirl.build(:field, field_label: nil).should_not be_valid
  end
end