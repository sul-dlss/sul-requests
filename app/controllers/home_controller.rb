# frozen_string_literal: true

# Controller to handle root HTTP
# connections and display the home page
class HomeController < ApplicationController
  include FolioController

  bot_challenge

  before_action :authenticate_user!, only: [:show]

  def show
    @dashboard = if patron_or_group.is_a? Folio::ProxyGroup
                   Home::Dashboard.new(aeon: Aeon::NullUser.new, patron: patron_or_group)
                 else
                   Home::Dashboard.new(aeon: current_user.aeon, patron: patron_or_group)
                 end
  end

  def authenticate_user!
    return if current_user.persisted?

    render 'login'
  end
end
