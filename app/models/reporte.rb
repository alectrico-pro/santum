class Reporte < ApplicationRecord
  broadcasts_refreshes
  include Linea

  has_many :comentarios, dependent: :destroy
  has_rich_text :contenido

  validates_presence_of :nombre
  validates :nombre, length: { in: 2..25}

  validates_presence_of :fono
#  validates :fono, length: { in: 9..9}

  before_save :sanitize_fono
  after_save :confirmar_fono unless self.confirmed


  def sanitize_fono
    if fono.length  == 9
      self.fono = "56" + self.fono.strip
      linea.info "fono sanitizado Chile"
      linea.info self.fono
    end
    regex = /\D*/
    self.fono.gsub!(regex, '')
    linea.info "fono sanitizado"
    linea.info self.fono
  end

  def confirmar_fono
    ::Waba::Transaccion.new(:cliente).confirmar_fono self.fono, self.nombre
  end

  def reservar
    ::Waba::Transaccion.new(:colaborador).say_flow_reservar self.fono, self.nombre
  end

end
