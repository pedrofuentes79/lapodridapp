class CreateGameParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :game_participations do |t|
      t.references :player, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
