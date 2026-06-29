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

  def renew # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @response = FolioClient.new.renew_checkout(@checkout)
    update_checkouts([@response.updated_checkout]) if @response.success?

    respond_to do |format|
      format.html do
        if @response.success?
          flash[:success] = t 'mylibrary.renew_item.success_html', title: params['title']
        else
          flash[:error] = t 'mylibrary.renew_item.error_html', title: params['title']
        end
        redirect_to checkouts_path
      end
      format.turbo_stream
    end
  end

  # Renew all eligible items for a patron
  #
  # POST /checkouts/renew_eligible
  def renew_eligible # rubocop:disable Metrics/AbcSize
    eligible_renewals = @checkouts.select(&:renewable?)
    @responses = eligible_renewals.map { |checkout| FolioClient.new.renew_checkout(checkout) }
    update_checkouts(@responses.select(&:success?).map(&:updated_checkout))

    respond_to do |format|
      format.html do
        bulk_renewal_success_flash(@responses.select(&:success?))
        bulk_renewal_error_flash(@responses.reject(&:success?))

        redirect_to checkouts_path
      end
      format.turbo_stream
    end
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

  def update_checkouts(updated_checkouts)
    updates = updated_checkouts.index_by(&:id)
    @checkouts = @checkouts.map { |checkout| updates[checkout.id] || checkout }
  end

  def bulk_renewal_success_flash(responses)
    return unless responses.any?

    flash[:success] = I18n.t('mylibrary.renew_all_items.success_html', count: responses.length) # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def bulk_renewal_error_flash(responses)
    return unless responses.any?

    flash[:error] = I18n.t('mylibrary.renew_all_items.error_html', # rubocop:disable Rails/ActionControllerFlashBeforeRender
                           count: responses.length,
                           items: tag.ul(safe_join(responses.collect do |renewal|
                                                     tag.li(renewal.checkout.title.truncate_words(7))
                                                   end, '')))
  end

  # Make sure the checkout belongs to the user trying to do the renewal
  # and make sure the item is renewable
  def authorize_renew!
    raise CheckoutException, 'Error' if @checkout.item_category_non_renewable?
  end
end
