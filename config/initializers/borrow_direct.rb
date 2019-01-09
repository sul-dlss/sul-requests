BorrowDirect::Defaults.api_key = Settings.borrow_direct.api_key

BorrowDirect::Defaults.library_symbol = 'STANFORD'

BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE if Rails.env.production?
