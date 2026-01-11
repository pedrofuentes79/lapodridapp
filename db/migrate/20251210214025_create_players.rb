class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, collation: "NOCASE", null: false

      t.timestamps
    end
    add_index :players, [ :name ], unique: true
  end
end
