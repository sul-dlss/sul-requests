# frozen_string_literal: true

require 'rails_helper'

describe 'messages/edit' do
  before do
    @message = assign(:message, create(:message))
  end

  it 'renders the edit message form' do
    render

    assert_select 'form[action=?][method=?]', message_path(@message), 'post' do
      assert_select 'textarea#message_text[name=?]', 'message[text]'

      assert_select 'input#message_library[name=?]', 'message[library]'

      assert_select 'input#message_request_type[name=?]', 'message[request_type]'
    end
  end
end
