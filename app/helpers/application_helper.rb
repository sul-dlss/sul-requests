# nodoc: Autogenerated
module ApplicationHelper
  def dialog_column_class
    'col-md-6 col-md-offset-3'
  end

  def request_form_options
    { as: :request }.merge(bootstrap_form_layout_options).merge(request_form_html_options)
  end

  def request_form_html_options
    { html: { class: @request.class.model_name.param_key.tr('_', '-') } }
  end

  def bootstrap_form_layout_options
    { layout: :horizontal, label_col: label_column_class, control_col: content_column_class }
  end

  def label_column_class
    'col-sm-4'
  end

  def label_column_offset_class
    'col-sm-offset-4'
  end

  def content_column_class
    'col-sm-8'
  end

  def send_request_via_login_button(text = nil)
    button_tag(
      text || 'Send request<span class="btn-sub-text">login with SUNet ID</span>'.html_safe,
      id: 'send_request_via_sunet',
      class: 'btn btn-md btn-primary btn-full',
      data: { disable_with: 'Send request' }
    )
  end

  def render_markdown(markup)
    markdown_renderer.render(markup).html_safe
  end

  def time_tag(dt, format = :default, attr: {})
    content_tag :time, l(dt, format: format), attr.merge(datetime: dt) if dt
  end

  def render_user_information
    '<span class="sr-only">You are logged in as </span>'.html_safe +
      current_user.email_address
  end

  def request_params
    params.except(:controller, :action)
  end

  private

  def markdown_renderer
    Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
  end
end
