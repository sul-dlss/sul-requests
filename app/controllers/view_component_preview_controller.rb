# frozen_string_literal: true

# Development controller for lookbook.
class ViewComponentPreviewController < ApplicationController
  include ViewComponent::PreviewActions

  skip_authorization_check
end
