# frozen_string_literal: true

###
#  Helper module for broadcast message related markup
###
module MessagesHelper
  def link_to_edit_message(message)
    link_to ' Edit message',
            [:edit, message],
            class: 'btn
                    btn-sm
                    btn-secondary
                    edit-message
                    glyphicon
                    glyphicon-pencil'
  end

  def link_to_add_message(library_code, request_type)
    link_to ' Add message',
            new_message_path(library: library_code,
                             request_type: request_type),
            class: 'btn
                    btn-sm
                    btn-secondary
                    edit-message
                    glyphicon glyphicon-pencil'
  end

  def link_to_delete_message(message)
    link_to ' Delete message',
            message,
            method: :delete,
            class: 'btn
                    btn-sm
                    btn-secondary
                    edit-message
                    glyphicon
                    glyphicon-trash'
  end
end
