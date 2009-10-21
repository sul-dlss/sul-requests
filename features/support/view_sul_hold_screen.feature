Feature: Test to see if we get Hold screen for SUL library

As a user
I want to see the hold screen for SUL libraries when I create a new request
with the appropriate parameters


Scenario: When location is CHECKEDOUT etc. I should see a Hold screen etc.
  When I follow requests/new?ckey=4037627&call_num=PS3573+.O64524+F76+1995&req_type=REQ-HOLD&home_lib=GREEN&current_loc=CHECKEDOUT&item_id=36105021328286&due_date=6/30/2010 request/new?req_type=CHECKEDOUT
  Then I should see "HOLD for SUL"