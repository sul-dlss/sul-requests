require "spec_helper"

include Requestutils

describe Requestutils do
  
  describe "parse Socrates URL" do
    
    it "should return a hash of elements from the URL" do
      url = "javascript:open_win('http://jenson.stanford.edu:9081/pls/sirwebdad/func_request_sal3b.display_form?p_SUNet_key=&p_data=|146360102|/uhtbin/cgisirsi/?ps=QDpIfPEmFT/GREEN|2504272|SAL3|STACKS|PQ2631+.R63+Z468+1931|36105002581994|REQ-SAL3'%20)"
      result = parse_soc_url( url )
      result.should include({:item_id=>"36105002581994", :req_type=>"REQ-SAL3"})
    end
    
  end
  
  #=========== get_rec_hold_type ==============
    
  describe "get hold or req type" do
    
    it "should get REQ_HOLD for current_loc = CHECKEDOUT and no req_hold_parm" do
      result = get_rec_hold_type( 'CHECKEDOUT', '')
      result.should eql('REQ-HOLD')
    end
    
  end
  

  #========== get_req_def ====================
  
  describe "get_req_def for lib = SAL3 and current loc PAGE-ARTLCK" do
    
    describe "when lib is SAL3 and current loc is PAGE-ARTLCK" do 
      
      before(:each) do
        @home_lib = 'SAL3'
        @current_loc = 'PAGE-AR'
        @result = get_req_def( @home_lib, @current_loc )
      end
      
      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-ARTLCK")
      end
      
    end
    
  end
  
  describe "get_req_def lib BUSINESS and various curr_locs " do
    
    describe "when lib is BUSINESS and cur loc is PAGE-IRON" do
      
      before(:each) do
        @home_lib = 'BUSINESS'
        @current_loc = 'PAGE-IRON'
        @result = get_req_def( @home_lib, @current_loc )
      end
      
      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-BUSINESS")
      end
      
    end
    
    describe "when lib is BUSINESS and cur loc is PAGE-BU" do
      
      before(:each) do
        @home_lib = 'BUSINESS'
        @current_loc = 'PAGE-BU'
        @result = get_req_def( @home_lib, @current_loc )
      end
      
      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-BUSINESS")
      end
      
    end
    
    describe "when lib is BUSINESS and cur loc is STACKS" do
      
      before(:each) do
        @home_lib = 'BUSINESS'
        @current_loc = 'STACKS'
        @result = get_req_def( @home_lib, @current_loc )
      end
      
      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("NON-PAGE")
      end
      
    end
    
    describe "when lib is BUSINESS and cur loc is IN-PROCESS" do
      
      before(:each) do
        @home_lib = 'BUSINESS'
        @current_loc = 'IN-PROCESS'
        @result = get_req_def( @home_lib, @current_loc )
      end
      
      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("NON-PAGE")
      end
      
    end
    
  end


  describe "get_req_def lib SAL cur_loc STACKS" do

    describe "when lib is SAL and cur loc is STACKS" do

      before(:each) do
        @home_lib = 'SAL'
        @current_loc = 'STACKS'
        @result = get_req_def( @home_lib, @current_loc )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-SAL")
      end

    end

  end

  describe "get_req_def lib SAL and cur loc CHECKEDOUT" do

    describe "when lib is SAL and cur loc is CHECKEDOUT" do

      before(:each) do
        @home_lib = 'SAL'
        @current_loc = 'CHECKEDOUT'
        @result = get_req_def( @home_lib, @current_loc )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-SAL")
      end

    end

  end

  describe "get_req_def lib SAL3 and cur loc STACKS" do

    describe "when lib is SAL3 and cur loc is STACKS" do

      before(:each) do
        @home_lib = 'SAL3'
        @current_loc = 'STACKS'
        @result = get_req_def( @home_lib, @current_loc )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-SAL3")
      end

    end

  end

  describe "get_req_def lib SAL3 and cur loc PAGE-MP" do

    describe "when lib is SAL3 and cur loc is PAGE-MP" do

      before(:each) do
        @home_lib = 'SAL3'
        @current_loc = 'PAGE-MP'
        @result = get_req_def( @home_lib, @current_loc )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-BRANNER")
      end

    end

  end

  describe "get_req_def lib SAL-NEWARK and cur loc STACKS" do

    describe "when lib is SAL-NEWARK and cur loc is STACKS" do

      before(:each) do
        @home_lib = 'SAL-NEWARK'
        @current_loc = 'STACKS'
        @result = get_req_def( @home_lib, @current_loc )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-SALNEWARK")
      end

    end

  end

  describe "get_req_def lib HOPKINS and cur loc STACKS" do

    describe "when lib is SAL-NEWARK and cur loc is STACKS" do

      before(:each) do
        @home_lib = 'HOPKINS'
        @current_loc = 'STACKS'
        @result = get_req_def( @home_lib, @current_loc )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("PAGE-HOPKINS")
      end

    end

  end

  #============ get_request_type


  describe "get_request_type lib BUSINESS various cur locs" do

    describe "when lib is BUSINESS and cur loc is STACKS" do

      before(:each) do
        home_lib, current_loc, req_type_parm, extras = {}
        @home_lib = 'BUSINESS'
        @current_loc = 'STACKS'
        @req_type_parm = ''
        @extras = { }
        @result = get_request_type( @home_lib, @current_loc, @req_type_parm, @extras )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("REQ-PAGE")
      end

    end
    
    describe "when lib is BUSINESS and cur loc is PAGE-BU" do

      before(:each) do
        home_lib, current_loc, req_type_parm, extras = {}
        @home_lib = 'BUSINESS'
        @current_loc = 'PAGE-BU'
        @req_type_parm = ''
        @extras = { }
        @result = get_request_type( @home_lib, @current_loc, @req_type_parm, @extras )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("REQ-PAGE")
      end

    end
    
    describe "when lib is BUSINESS and cur loc is ON-ORDER" do

      before(:each) do
        home_lib, current_loc, req_type_parm, extras = {}
        @home_lib = 'BUSINESS'
        @current_loc = 'ON-ORDER'
        @req_type_parm = ''
        @extras = { }
        @result = get_request_type( @home_lib, @current_loc, @req_type_parm, @extras )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("REQ-ONORDM")
      end

    end

  end
  describe "get_request_type lib GREEN and cur loc INPROCESS" do

    describe "when lib is GREEN and cur loc is INPROCESS" do

      before(:each) do
        home_lib, current_loc, req_type_parm, extras = {}
        @home_lib = 'GREEN'
        @current_loc = 'INPROCESS'
        @req_type_parm = ''
        @extras = { }
        @result = get_request_type( @home_lib, @current_loc, @req_type_parm, @extras )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("REQ-INPRO")
      end

    end

  end


  describe "get_request_type lib GREEN and cur loc ON-ORDER" do

    describe "when lib is GREEN and cur loc is ON-ORDER" do

      before(:each) do
        home_lib, current_loc, req_type_parm, extras = {}
        @home_lib = 'GREEN'
        @current_loc = 'ON-ORDER'
        @req_type_parm = ''
        @extras = { }
        @result = get_request_type( @home_lib, @current_loc, @req_type_parm, @extras )
      end

      it "should return the correct request definition" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("REQ-ONORDM")
      end

    end

  end

  #============ get_pickup_key

  describe "getPickupKey should get correct key for various situations" do

    describe "when home lib SPEC-COLL" do

      before(:each) do
        @home_lib = 'SPEC-COLL'
        @home_loc = 'STACKS'
        @current_loc = 'STACKS'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("SPEC-COLL")
      end

    end

    describe "when PAGE-IRON" do

      before(:each) do
        @home_lib = 'BUSINESS'
        @home_loc = 'PAGE-IRON'
        @current_loc = 'PAGE-IRON'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("IRON")
      end

    end
    
    describe "when PAGE-BU" do

      before(:each) do
        @home_lib = 'BUSINESS'
        @home_loc = 'PAGE-BU'
        @current_loc = 'PAGE-BU'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("BU")
      end

    end
    
    describe "when PAGE-BU" do

      before(:each) do
        @home_lib = 'BUSINESS'
        @home_loc = 'PAGE-BU'
        @current_loc = 'CHECKEOUT'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("BU")
      end

    end

    describe "when PAGE-MP" do

      before(:each) do
        @home_lib = 'SAL'
        @home_loc = 'PAGE-MP'
        @current_loc = 'PAGE-MP'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("MP")
      end

    end

    describe "when HY-PAGE-EA" do

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

    describe "when PAGE-MP" do

      before(:each) do
        @home_lib = 'SAL'
        @home_loc = 'PAGE-MP'
        @current_loc = 'PAGE-MP'
        @req_type = nil
        @result = get_pickup_key( @home_lib, @home_loc, @current_loc, @req_type )
      end

      it "should return the correct pickupkey" do
        #To change this template use File | Settings | File Templates.
        @result.should eql("MP")
      end

    end

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