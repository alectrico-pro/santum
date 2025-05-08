class Reporte < ApplicationRecord
  include Linea

  has_many :comentarios, dependent: :destroy
  has_rich_text :contenido

  validates_presence_of :nombre
  validates :nombre, length: { in: 2..25}

  validates_presence_of :fono
#  validates :fono, length: { in: 9..9}

  before_save :sanitize_fono_chile
  before_save :sanitize_fono_usa

  after_save :confirmar_fono


  def sanitize_fono_usa
    regex = /^\+1|[^0-9]+/g;
    self.fono.replace(regex, '')
    linea.info "fono sanitizado USA"
    linea.info self.fono
  end

  def sanitize_fono_chile
    if fono.length  == 9
      self.fono = "56" + self.fono.strip
      linea.info "fono sanitizado Chile"
      linea.info self.fono
    end
  end

  def confirmar_fono
    ::Waba::Transaccion.new(:cliente).confirmar_fono self.fono, self.nombre
  end

  def reservar
    ::Waba::Transaccion.new(:colaborador).say_flow_reservar self.fono, self.nombre
  end

end
