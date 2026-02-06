class AddDisplayTypeToPatronRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :patron_requests, :display_type, :string
    add_index :patron_requests, :display_type

    reversible do |dir|
      dir.up do
        PatronRequest.find_each do |request|
          request.update(display_type: request.calculate_display_type)
        end
      end
    end
  end
end
