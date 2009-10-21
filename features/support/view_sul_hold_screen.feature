Feature: Test to see if we get Hold screen for SUL library

As a user
I want to see the hold screen for SUL libraries when I create a new request
with the appropriate parameters


Scenario: When location is CHECKEDOUT etc. I should see a Hold screen etc.
  #Given I am on   "requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT"
  #When I go to  "requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT"
  When I go to "request/new?ckey%3D4037627%26call_num%3DPS3573%2B.O64524%2BF76%2B1995%26req_type%3DREQ-HOLD%26home_lib%3DGREEN%26current_loc%3DCHECKEDOUT%26item_id%3D36105021328286%26due_date%3D6%2F30%2F2010+request%2Fnew%3Freq_type%3DCHECKEDOUT"
  Then I should see "HOLD for SUL"

#Scenario: Go to list of request definitions and see appropriate heading
#When I go to "admin/requestdefs"
#Then I should see "Request Definitions"