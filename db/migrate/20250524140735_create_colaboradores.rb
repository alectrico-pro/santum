class CreateColaboradores < ActiveRecord::Migration[8.0]
  def change
    create_table :colaboradores do |t|
      t.string :nombre
      t.integer :fono

      t.timestamps
    end
  end
end
