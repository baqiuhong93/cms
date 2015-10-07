class CreateMessageColumns < ActiveRecord::Migration
  def change
    create_table :message_columns do |t|
      t.references :message_table
      t.string :name
      t.string :column_name
      t.boolean :show_index
      t.boolean :export
      t.integer :sortrank
      t.integer :type_id
      t.string :type_value
      
      t.timestamps
    end
    add_index :message_columns, :message_table_id
  end
end
