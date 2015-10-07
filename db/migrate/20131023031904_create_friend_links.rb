class CreateFriendLinks < ActiveRecord::Migration
  def change
    create_table :friend_links do |t|
      t.string :name
      t.string :description
      t.integer :sortrank
      t.string :addr
      t.string :type_ids
      t.string :img_path
      t.integer :status
      t.reference :user
      t.string :name

      t.timestamps
    end
  end
end
