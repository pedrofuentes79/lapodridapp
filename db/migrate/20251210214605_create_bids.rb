class CreateBids < ActiveRecord::Migration[8.1]
  def change
    create_table :bids do |t|
      t.references :round, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :predicted_tricks, default: nil
      t.integer :actual_tricks, default: nil

      t.timestamps
    end
    add_index :bids, [ :round_id, :player_id ], unique: true
  end
end
