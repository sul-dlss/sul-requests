require 'spec_helper'

describe Request do
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    Request.create!(@valid_attributes)
  end
end
