# frozen_string_literal: true

# Controller for the Checkouts page
class CheckoutsController < ApplicationController
  include ActionView::Context
  include ActionView::Helpers::TagHelper
  include FolioController

  before_action :authenticate_user!

  before_action :load_checkouts
  before_action :load_checkout, except: [:index, :renew_eligible]

  before_action :authorize_renew!, only: [:renew]

  # Render a list of checkouts for the patron
  #
  # GET /checkouts
  # GET /checkouts.json
  def index; end

  def renew # rubocop:disable Metrics/AbcSize
    @response = FolioClient.new.renew_item_by_id(patron_or_group.key, @checkout.item_id)

    if @response.status.in?([200, 201])
      flash[:success] = t 'mylibrary.renew_item.success_html', title: params['title']
    else
      flash[:error] = t 'mylibrary.renew_item.error_html', title: params['title']
    end

    redirect_to checkouts_path
  end

  # Renew all eligible items for a patron
  #
  # POST /checkouts/renew_eligible
  def renew_eligible
    eligible_renewals = @checkouts.select(&:renewable?)
    response = FolioClient.new.renew_items(eligible_renewals)

    bulk_renewal_success_flash(response)
    bulk_renewal_error_flash(response)

    redirect_to checkouts_path(group: params[:group])
  end

  private

  def renew_item_id_param
    params.require(:id)
  end

  def load_checkouts
    @checkouts = patron_or_group.checkouts.sort_by { |x| x.sort_key(:due_date) }
  end

  def load_checkout
    @checkout = @checkouts.find { |checkout| checkout.item_id == params[:id] }

    raise ActiveRecord::RecordNotFound, 'Checkout not found' if @checkout.nil?
  end

  def bulk_renewal_success_flash(response)
    return unless response[:success].any?

    flash[:success] = I18n.t('mylibrary.renew_all_items.success_html', count: response[:success].length) # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def bulk_renewal_error_flash(response)
    return unless response[:error].any?

    flash[:error] = I18n.t('mylibrary.renew_all_items.error_html', # rubocop:disable Rails/ActionControllerFlashBeforeRender
                           count: response[:error].length,
                           items: tag.ul(safe_join(response[:error].collect do |renewal|
                                                     tag.li(renewal.title.truncate_words(7))
                                                   end, '')))
  end

  # Make sure the checkout belongs to the user trying to do the renewal
  # and make sure the item is renewable
  def authorize_renew!
    raise CheckoutException, 'Error' if @checkout.item_category_non_renewable?
  end
end
