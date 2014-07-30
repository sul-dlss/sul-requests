module Constants
  include EnvironmentConstants
  # Defines constants that may be used in various places
 
 # Libraries from which all items can be requested
  PAGE_LIBS = ["SAL", "SAL3", "SAL-NEWARK", "HOPKINS", "EAST-ASIA"]

  # Locs that are equivalent to checked out
  CHECKED_OUT_LOCS = ["CHECKEDOUT", "CHKD-OUT-D", "BINDERY", "SUL-BIND", 
                      "B&F-HOLD", "ENDPROCESS", "REPAIR", "LOST-ASSUM"]
                      
  MISSING_LOCS = ["MISSING", "MISS-INPRO"]  
  
  # Also need to check programmatically for locs that include 
  # string "-LOAN" at the end
  NOT_ON_SHELF_LOCS = ["INTRANSIT"]
  
  # Locations for title-level holds (removed INPROCESS per Darsi 1020/2010
  TITLE_LEVEL_LOCS = ["ON-ORDER" ]
  
  # Locations for hold_recall flag (also check "-LOAN" programmatically
  # Don't include INPROCESS here because we need to handle that separately
  REC_HOLD_LOCS = CHECKED_OUT_LOCS + MISSING_LOCS + NOT_ON_SHELF_LOCS 
 
  # Locations that get non-page request form (also check "-LOAN" programmatically)
  NON_PAGE_LOCS = ["NEWBOOKS"] + TITLE_LEVEL_LOCS + REC_HOLD_LOCS

  # SAL locations for items that are available on the shelf 
  SAL_ON_SHELF_LOCS = ["STACKS", "SAL-SERG", "FED-DOCS", "SAL-MUSIC", "SAL-PAGE"]   
  
  # Display text for location codes in items area (used in syminfo.get_item_text)
  TEXT_FOR_LOC_CODES = { :INPROCESS => 'In Process', :MISSING => 'Missing',
    :NEWBOOKS => 'New Book Shelf', :ONORDER => 'On Order',
    :CHECKEDOUT => 'Checked Out', :NOTONSHELF => 'Not On Shelf'
  }
  
  # Default maximum number of checked items
  MAX_CHECKED_ITEMS = 10
  
  # No. of days from today for start and end dates of not needed after and planned use fields
  NOT_NEEDED_AFTER_START = 2
  NOT_NEEDED_AFTER_END = 730 # 2 years
  PLANNED_USE_START = 1
  PLANNED_USE_END = 730 # 2 years

end
