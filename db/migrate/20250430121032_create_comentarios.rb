class CreateComentarios < ActiveRecord::Migration[7.0]
  def change
    create_table :comentarios do |t|
      t.references :reporte, null: false, foreign_key: true
      t.text :contenido

      t.timestamps
    end
  end
end
