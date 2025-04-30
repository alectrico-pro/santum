class Reporte < ApplicationRecord
  has_many :comentarios, dependent: :destroy
  has_rich_text :contenido
  validates_presence_of :nombre
end
