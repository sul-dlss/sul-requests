# frozen_string_literal: true

# helpers methods for Aeon requests views
module AeonRequestsHelper
  def update_requests_component_for(request)
    if request.multi_item_selector?
      Aeon::RequestGroupItemComponent.new(request: request)
    else
      Aeon::RequestComponent.new(request: request)
    end
  end
end
