# frozen_string_literal: true

# Handle application errors
class ErrorsController < ApplicationController
  def forbidden
    render(status: :forbidden)
  end

  def not_found
    render(status: :not_found)
  end

  def internal_server_error
    if FolioGraphqlClient.new.ping
      render(status: :internal_server_error)
    else
      render('folio_down', status: :internal_server_error)
    end
  end
end
