###
#  Controller to handle particular behaviors for Scan type requests
###
class ScansController < RequestsController
  def current_request
    @scan ||= Scan.new
  end

  protected

  def redirect_to_success_with_token
    redirect_to illiad_query(current_request)
  end

  def illiad_query(scan)
    illiad_params = {
      'Action': '10', 'Form': '30', 'rft.genre': 'scananddeliverArticle',
      'rft.jtitle': scan.item_title,
      'rft.au': scan.data[:authors],
      'rft.pages': scan.data[:page_range],
      'rft.atitle': scan.data[:section_title],
      'rft.volume': scan.holdings.first.callnumber,
      'scan_referrer': successful_scan_url(scan)
    }
    Settings.sul_illiad + "#{illiad_params.to_query}"
  end

  def validate_request_type
    fail UnscannableItemError unless @scan.scannable?
  end

  class UnscannableItemError < StandardError
  end
end
