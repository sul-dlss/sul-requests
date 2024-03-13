# frozen_string_literal: true

# nodoc: Autogenerated
module ApplicationHelper
  def dialog_column_class
    'col-lg-6 offset-lg-3'
  end

  def request_form_options
    { as: :request }.merge(bootstrap_form_layout_options).merge(request_form_html_options)
  end

  def request_form_html_options
    { html: { class: @request.class.model_name.param_key.tr('_', '-'), data: { turbo: false } } }
  end

  def bootstrap_form_layout_options
    { layout: :horizontal, label_col: label_column_class, control_col: content_column_class }
  end

  def label_column_class
    'col-sm-4'
  end

  def label_column_offset_class
    'offset-sm-4'
  end

  def content_column_class
    'col-sm-8'
  end

  def send_request_via_login_button(text = nil)
    button_tag(
      text || 'Send request<span class="btn-sub-text">login with SUNet ID</span>'.html_safe,
      id: 'send_request_via_sunet',
      class: 'btn btn-md btn-primary btn-full',
      data: { disable_with: 'Send request', additional_user_validation: 'false' }
    )
  end

  def render_markdown(markup)
    markdown_renderer.render(markup).html_safe
  end

  def time_tag(dt, format = :default, attr: {})
    content_tag :time, l(dt, format:), attr.merge(datetime: dt) if dt
  end

  def render_user_information
    '<span class="visually-hidden">You are logged in as </span>'.html_safe +
      current_user.email_address
  end

  def request_params
    params.except(:controller, :action).to_unsafe_h
  end

  def sort_holdings(holdings_object)
    holdings_object.sort_by { |item| digit_match(item) }
  end

  def enumeration_month(enumeration)
    monthconversion = { 'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4, 'may' => 5, 'june' => 6,
                        'july' => 7, 'aug' => 8, 'sept' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12 }
    hasmonth = enumeration.downcase.scan(/(#{monthconversion.keys.join('|')})/)

    return 0 if hasmonth.empty?

    monthconversion[hasmonth.last[0]]
  end

  def enumeration_year_volume(enumeration_numbers, defaultvalues, enumeration)
    enumeration_numbers.each do |number|
      if number.length == 4
        defaultvalues[:year] = number.to_i
      else
        defaultvalues[:volume] = number.to_i
        volume_letter_check = /#{defaultvalues[:volume]}([A-Za-z])/.match(enumeration)
        defaultvalues[:volume_letter] = volume_letter_check[1] if volume_letter_check.present?
      end
    end
    defaultvalues
  end

  def digit_match(item)
    enumeration = item.enumeration
    defaultvalues = { year: 4000, volume: 0, volume_letter: '' }
    return [item.callnumber_no_enumeration] unless enumeration

    enumeration_numbers = item.enumeration.split(/\D+/)

    return [item.callnumber_no_enumeration] if enumeration_numbers.empty?

    month = enumeration_month(enumeration)
    enum_y_v = enumeration_year_volume(enumeration_numbers, defaultvalues, enumeration)

    # sorts by callnumber without year, volume, sorts year desc, volume asc, volume letter asc (28A, 28B), and month descending
    [item.callnumber_no_enumeration, -enum_y_v[:year], enum_y_v[:volume], enum_y_v[:volume_letter], -month]
  end

  private

  def markdown_renderer
    Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
  end
end
