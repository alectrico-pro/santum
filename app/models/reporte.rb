class Reporte < ApplicationRecord
  broadcasts_refreshes if C.turbo_enabled
  include Linea

  has_many :comentarios, dependent: :destroy
  #has_rich_text :contenido

  validates_presence_of :nombre
  validates :nombre, length: { in: 2..25}

  validates_presence_of :fono
#  validates :fono, length: { in: 9..9}

  before_save :sanitize_fono
  after_save :confirmar_fono 

  broadcasts_to ->(reporte) { "reportes" }, inserts_by: :prepend if C.turbo_enabled

  scope :ordered, -> { order(id: :desc) }

  def actualiza
    broadcast_update_to( self, :confirmado, target: "reporte_#{self.id}", html: "<p> #{self.confirmado} </p>")
  end


  private

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

  #ef broadcast_reporte
  # Turbo::StreamsChannel.broadcast_replace_to "reporte", target: "reporte_#{id}", partial: "reportes/reporte", locals: { reporte: self }
 #end

  def confirmar_fono
    unless self.confirmado
      ::Waba::Transaccion.new(:cliente).confirmar_fono self.fono, self.nombre
     # Turbo.visit("/reportes/id", { action: "replace" })
    end
  end

  def reservar
    ::Waba::Transaccion.new(:colaborador).say_flow_reservar self.fono, self.nombre
  end

end
