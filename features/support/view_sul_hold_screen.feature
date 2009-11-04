Feature: Test to see if we get Hold screen for SUL library

As a user
I want to see the hold screen for SUL libraries when I create a new request
with the appropriate parameters

#Scenario: Go to list of request definitions and see appropriate heading
#When I go to "admin/requestdefs"
#Then I should see "Sorry, you are not"

Scenario: When location is CHECKEDOUT etc. I should see a Hold screen etc.
  #Given I am on   "requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT"

  # With Rail config, first of these gets "bad URI" and second 
  #When I go to  "requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT"
  #When I go to "request/new?ckey%3D4037627%26call_num%3DPS3573%2B.O64524%2BF76%2B1995%26req_type%3DREQ-HOLD%26home_lib%3DGREEN%26current_loc%3DCHECKEDOUT%26item_id%3D36105021328286%26due_date%3D6%2F30%2F2010+request%2Fnew%3Freq_type%3DCHECKEDOUT"
  #Then I should see "HOLD for SUL"
  
  # Following gets message "need absolute URL" with mechanize config WTF! This is an abolute URL
  # When I go to "http://localhost:3000/requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT"
  # Then I should see "HOLD for SUL"
  
  #Given I have opened "http://localhost:3000/requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT"
  #Given I have opened "http://www.google.com"
  #Then I should see "Google"
  
When I land on requests/new with ckey="4037627" and req_type="REQ-HOLD" and current_loc="CHECKEDOUT" and item_id="36105021328286" and home_lib="GREEN"
Then I should see "HOLD for SUL"

#Scenario: testing
#  When I land on requests/newx with ckey="75842"
#  Then I should see "75842"

