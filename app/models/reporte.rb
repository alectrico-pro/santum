class Reporte < ApplicationRecord
  has_many :comentarios, dependent: :destroy
  has_rich_text :contenido

  #validates_presence_of :nombre
  #validates :nombre, length: { in: 2..25}

  validates_presence_of :fono
  validates :fono, length: { in: 9..9}
  def confirmar_fono
    ::Waba::Transaccion.new(:cliente).confirmar_fono self.fono
  end
end
