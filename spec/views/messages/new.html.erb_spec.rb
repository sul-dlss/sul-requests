# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'messages/new' do
  before do
    @message = assign(:message, build(:message))
  end

  it 'renders new message form' do
    render

    assert_select 'form[action=?][method=?]', messages_path, 'post' do
      assert_select 'textarea#message_text[name=?]', 'message[text]'

      assert_select 'input#message_library[name=?]', 'message[library]'

      assert_select 'input#message_request_type[name=?]', 'message[request_type]'
    end
  end
end
