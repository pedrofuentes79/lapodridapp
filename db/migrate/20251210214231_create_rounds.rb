class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :round_number
      t.integer :cards_dealt

      t.timestamps
    end
  end
end
