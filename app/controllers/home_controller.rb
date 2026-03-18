# frozen_string_literal: true

# Controller to handle root HTTP
# connections and display the home page
class HomeController < ApplicationController
  bot_challenge

  before_action :authenticate_user!, only: [:show]

  def show; end

  def authenticate_user!
    return if current_user.persisted?

    render 'login'
  end
end
