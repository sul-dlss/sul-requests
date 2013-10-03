require "spec_helper"

include Requestmod

describe Requestmod do
  
  describe "get field labels " do
    fixtures :fields
    
    it "should get field labels" do
      @result = get_field_labels
      @result.should include( { "ckey" => "CKEY", "patron_email" => "E-mail"})
    end
    
  end
  
  describe "get library names" do
    fixtures :libraries
    
    it "should get library names" do
      @result = get_library_names
      #@result.should =~ /.*?Hopkins Marine Station Library [Miller].*?SPEC-DESK.*$/
      @result.should include( {"ARS" => "Archive of Recorded Sound", "MUSIC" => "Music"})
    end
  end
  
  describe "get_pickup_libs for various pickupkyes" do
    fixtures :libraries, :pickupkeys
    
    describe "when pickupkey is BU" do
      
      before(:each) do
        @pickupkey = 'BU'
        @result = get_pickup_libs( @pickupkey )
      end
      
      it "should return the correct pickup libraries" do
        #To change this template use File | Settings | File Templates.
        @result.should eql([["Business Library", "BUSINESS"]])
      end
      
    end
    
    describe "when pickupkey is AR" do
      
      before(:each) do  
        @pickupkey = 'AR'
        @result = get_pickup_libs( @pickupkey )
      end
      
      it "should return the correct pickup libraries" do
        #To change this template use File | Settings | File Templates.
        @result.should eql([["Art", "ART"]])
      end
      
    end
    
  end
  
end