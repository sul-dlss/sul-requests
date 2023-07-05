# frozen_string_literal: true

# This is a log of the requests made to the FOLIO API.
# We keep this log so that we can see the request made on the debug page
class FolioCommandLog < ApplicationRecord
  belongs_to :request
end
