require "spec_helper"

include RequestsHelper


describe RequestsHelper do

  describe "link_for_cancel" do

    describe "when SO" do

      before(:each) do
        @source = "SO"
        @return_url = "http://socrates.stanford.edu/"
        @result = link_for_cancel(@source, @return_url)
      end

      it "should return the correct link" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("javascript:self.close()")
      end
      
    end

    describe "when SW" do

      before(:each) do
        @source = "SW"
        @return_url = "http://searchworks.stanford.edu"
        @result = link_for_cancel(@source, @return_url)
      end

      it "should return the correct link" do
        #To change this template use File | Settings | File Templates.
        @result.should eql(@return_url)
      end

    end

    describe "when nothing" do

      before(:each) do
        @source = ""
        @return_url = "http://searchworks.stanford.edu"
        @result = link_for_cancel(@source, @return_url)
      end

      it "should return the correct link" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("javascript:history.go(-1)")
      end

    end


  end
  
end