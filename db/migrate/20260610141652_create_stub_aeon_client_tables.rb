class CreateStubAeonClientTables < ActiveRecord::Migration[8.1]
  def change
    create_table :stub_aeon_client_users do |t|
      t.string :username, index: { unique: true }
      t.text :data

      t.timestamps
    end

    create_table :stub_aeon_client_requests do |t|
      t.text :data

      t.timestamps
    end

    create_table :stub_aeon_client_appointments do |t|
      t.text :data

      t.timestamps
    end

    create_table :stub_aeon_client_activities do |t|
      t.text :data

      t.timestamps
    end

    create_table :stub_aeon_client_reading_rooms do |t|
      t.text :data
      t.text :closures

      t.timestamps
    end

    create_table :stub_aeon_client_queues do |t|
      t.text :data

      t.timestamps
    end
  end
end
