class AddRequestTypeToPatronRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :patron_requests, :request_type, :string

    add_index :patron_requests, :request_type

    reversible do |dir|
      dir.up do
        PatronRequest.find_each do |request|
          request.update(request_type: request.data['request_type'])
        end
      end
    end
  end
end
