class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, collation: "NOCASE"

      t.timestamps
    end
  end
end
