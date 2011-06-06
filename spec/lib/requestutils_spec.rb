require "spec_helper"

include Requestutils

describe Requestutils do

  describe "getPickupKey PAGE-EA" do

    describe "when PAGE-EA" do

      before(:each) do
        @home_lib = 'SAL'
        @home_loc = 'HY-PAGE-EA'
        @current_loc = 'HY-PAGE-EA'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("EA")
      end

    end

  end

    describe "getPickupKey UARCH-30" do

    describe "when PAGE-EA" do

      before(:each) do
        @home_lib = 'SAL'
        @home_loc = 'UARCH-30'
        @current_loc = 'UARCH-30'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("UARCH")
      end

    end

  end


end