class CreateMessageTables < ActiveRecord::Migration
  def change
    create_table :message_tables do |t|
      t.string :name
      t.string :description
      t.string :table_name
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :logined
      t.integer :user_id
      t.string :user_name

      t.timestamps
    end
  end
end
