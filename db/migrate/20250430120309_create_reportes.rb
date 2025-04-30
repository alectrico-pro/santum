class CreateReportes < ActiveRecord::Migration[7.0]
  def change
    create_table :reportes do |t|
      t.string :nombre
      t.text :contenido

      t.timestamps
    end
  end
end
