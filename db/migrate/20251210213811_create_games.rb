class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :game_id
      t.integer :current_round_number, default: 0
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
