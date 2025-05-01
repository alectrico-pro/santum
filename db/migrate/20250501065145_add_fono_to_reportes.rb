class AddFonoToReportes < ActiveRecord::Migration[7.0]
  def change
    add_column :reportes, :fono, :integer
  end
end
