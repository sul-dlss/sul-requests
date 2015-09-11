###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadOpenurl
  def initialize(current_user, scan, redirect_url)
    @current_user = current_user
    @scan = scan
    @redirect_url = redirect_url
  end

  def param_constants
    { 'Action': '10', 'Form': '30', 'rft.genre': 'scananddeliver' }
  end

  def item_data
    { 'rft.location': @scan.origin,
      'rft.call_number': first_holding.try(:callnumber),
      'rft.item': first_holding.try(:barcode) }
  end

  def citation_data
    { 'rft.jtitle': @scan.item_title,
      'rft.au': @scan.authors,
      'rft.pages': @scan.data[:page_range],
      'rft.atitle': @scan.data[:section_title] }
  end

  def callback_url
    { 'scan_referrer': @redirect_url }
  end

  def query_params
    [param_constants, item_data, citation_data, callback_url].reduce({}, :merge).to_query
  end

  def to_url
    Settings.sul_illiad + '/' + nvtgc + '/illiad.dll?' + "#{query_params}"
  end

  private

  def first_holding
    @scan.holdings.first
  end

  def nvtgc
    illiad_nvtgc_config.each do |k, v|
      return v if @current_user && @current_user.ldap_groups.include?(k)
    end

    illiad_nvtgc_config[:default]
  end

  def illiad_nvtgc_config
    SULRequests::Application.config.illiad_nvtgc_map
  end
end
