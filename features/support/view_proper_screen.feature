Feature: Test to see if we get the correct screen for parameters we supply

As a user
I want to see the correct screen when I create a new request with the appropriate parameters

Scenario: When location is CHECKEDOUT I should see a Hold screen.  
  
When I land on requests/new with ckey="4037627" and req_type="REQ-HOLD" and current_loc="CHECKEDOUT" and item_id="36105021328286" and home_lib="GREEN"
Then I should see "Hold for SUL"

# Looks like there are no on-order or in-process items in Searchworks
# Scenario: When location is ON-ORDER and library is LAW I should see "Law on-order"
# When I land on requests/new with ckey="8348287" and req_type="NOTIF-ORD" and current_loc="ON-ORDER" and home_lib="LAW"
# Then I should see "Law on-order"