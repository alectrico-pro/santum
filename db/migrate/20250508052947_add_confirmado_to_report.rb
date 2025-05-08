class AddConfirmadoToReport < ActiveRecord::Migration[8.0]
  def change
    add_column :reportes, :confirmado, :boolean
  end
end
