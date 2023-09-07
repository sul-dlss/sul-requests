# frozen_string_literal: true

###
#  Module to mixin the permitted and required parameters for request controller actions
###
module RequestStrongParams
  # rubocop:disable Metrics/AbcSize
  def new_params
    if params[:origin] || params[:origin_location]
      # If you have one of these you must provide both
      params.require(:origin) # Legacy symphony library code
      params.require(:origin_location) # Legacy symphony location code
      params[:location] = FolioLocationMap.folio_code_for(library_code: params[:origin], home_location: params[:origin_location])
    else
      params.require(:location)
    end

    params.require(:item_id)
    params.permit(:origin, :item_id, :origin_location, :barcode, :location)
  end

  # rubocop:disable Metrics/MethodLength
  def create_params
    params.permit(:email)
    if params[:request] && params[:request][:origin] && params[:request][:origin_location]
      params[:request][:location] =
        FolioLocationMap.folio_code_for(library_code: params[:request][:origin], home_location: params[:request][:origin_location])
    end

    @create_params ||= params.require(:request).permit(:item_id, :origin, :origin_location, :location,
                                                       :destination, :needed_date, :estimated_delivery,
                                                       :item_comment, :request_comment,
                                                       :authors, :page_range, :section_title, # scans
                                                       :proxy,
                                                       barcodes: {},
                                                       public_notes: {},
                                                       user_attributes: [:name, :email, :library_id])
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def update_params
    params.permit(:email)
    params.require(:request).permit(:needed_date)
  end
end
