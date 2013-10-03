require 'spec_helper'

describe Request do
  
  # Can't find a way to set some variables initally and then do tests that change some of them. The let block seems to be the only
  # place where varialbles can be set. 
  

  #before(:each) do
  let (:request) {
    @params = { 'ckey' => '2504272', 'home_lib' => 'SAL3', 'home_loc' => 'STACKS', 'current_loc' => 'STACKS', 'not_needed_after' => '12/20/2013' }
    @env = {"HTTP_USER_AGENT" => "Some User Agent", 'WEBAUTH_LDAP_DISPLAYNAME' => 'Jon Lavigne'}
    @referrer = 'http://searchworks.stanford.edu/view/2504272'
    request = Request.new(@params, @env, @referrer)
  }
  #end
  
  # The extra param gets passed in but doesn't change the @not_needed_after var originally set by the let block
  it "should be valid when new" do
    #puts "===== request before " + request.inspect
    #request = Request.new(@params, @env, @referrer)
    request.params[:not_needed_after] = '12/25/2013'
    #request.referrer = 'blah'
    #request.not_needed_after = '12/25/2013'
    request.should be_valid
    #@request.should be_valid
    #puts "======= request after" + request.inspect
  end
  
  # Doesn't seem to be any way to add stuff to the env after the let block above.
  #it "should do something with the env" do
  #  request.env['WEBAUTH_LDAP_EMAIL'] = 'jlavigne@stanford.edu'
  #  puts "====== request is " + request.inspect
  #  request.should be_valid
  #end
  
  
end
  
=begin

  First two work but can't get change params
 it "has a valid factory" do 
   FactoryGirl.build(:request).should be_valid 
  end 
  
  it "should return a requestdef of PAGE-SAL3" do
    req = FactoryGirl.build(:request) 
    req.request_def.should=='PAGE-SAL3'
  end
  
  it "should return a not needed after date" do
    req = FactoryGirl.build(:request) 
    puts "======= req is " + req.inspect
    req.request_def.should=='PAGE-SAL3'
  end
=end  
  
