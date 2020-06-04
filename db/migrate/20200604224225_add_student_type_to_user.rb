class AddStudentTypeToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :student_type, :string
  end
end
