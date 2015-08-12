###
#  Class to handle creation of ILLiad OpenURL request
###
class IlliadOpenurl
  def initialize(scan, redirect_url)
    @scan = scan
    @redirect_url = redirect_url
  end

  def param_constants
    { 'Action': '10', 'Form': '30', 'rft.genre': 'scananddeliver' }
  end

  def item_data
    { 'rft.location': @scan.origin,
      'rft.call_number': @scan.holdings.first.callnumber,
      'rft.item': @scan.holdings.first.barcode }
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
    Settings.sul_illiad + '/st2/illiad.dll?' + "#{query_params}"
  end
end
