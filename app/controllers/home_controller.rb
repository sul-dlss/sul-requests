# frozen_string_literal: true

# Controller to handle root HTTP
# connections and display the home page
class HomeController < ApplicationController
  include FolioController

  bot_challenge

  before_action :authenticate_user!, only: [:show]
  before_action :load_dashboard

  def show; end

  def show_folio; end

  def show_aeon; end

  def load_dashboard
    @dashboard = if patron_or_group.is_a?(Folio::ProxyGroup) || !current_user.authenticated?
                   Home::Dashboard.new(aeon: Aeon::NullUser.new, patron: patron_or_group, include_illiad: false)
                 else
                   Home::Dashboard.new(aeon: current_user.aeon, patron: patron_or_group)
                 end
  end

  def authenticate_user!
    return if current_user.persisted?

    render 'login'
  end
end
