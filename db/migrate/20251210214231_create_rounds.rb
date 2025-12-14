class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :starts_at
      t.integer :round_number, null: false
      t.integer :cards_dealt, null: false
      t.boolean :has_trump, default: false, null: false

      t.timestamps
    end
  end
end
