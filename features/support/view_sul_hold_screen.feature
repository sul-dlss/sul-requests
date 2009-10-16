Feature: Test to see if we get Hold screen for SUL library

As a user
I want to see the hold screen for SUL libraries when I create a new request
with the appropriate parameters


Scenario: When location is  CHECKEDOUT etc. I should see a Hold screen etc.
  When I go to requests/new
  And current_loc is "CHECKEDOUT"
  And home_lib is not "HOOVER"
  Then I should see "Hold for SUL"