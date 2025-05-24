class Reporte < ApplicationRecord
  #Mi debugueer que se usa así: linea.info "Información que quiero mostra"
  include Linea
  broadcasts_refreshes if C.turbo_enabled #no sé cuando funciona ni si funciona

  #Relations
  has_many :comentarios, dependent: :destroy

  #no me sirve porque no puedo gastar en hospedaje de imágenes 
  #has_rich_text :contenido

  #Validates
  validates_presence_of :nombre
  validates :nombre, length: { in: 2..25}

  #El teléfono será validado en enviar_confirmar_fono
  validates :fono , presence: true, format: { with: VALID_FONO_REGEX}

  #validates :fono, length: { in: 9..9}

  #Callbacks
  before_save :sanitiza_fono
  after_save  :enviar_confirmar_fono 

  #Broadcasts
  broadcasts_to    -> ( reporte ) { [ reporte.fono, "reportes" ] }, inserts_by: :prepend if C.turbo_enabled
#  broadcasts_to    -> ( reporte ) { "reportes" }, inserts_by: :prepend if C.turbo_enabled
  
  #broadcast con callback
  after_commit -> ( reporte) { broadcast_replace_to "iconos", partial: "reportes/fonos", locals: { reporte: self }, target: "fonos" }


  #Scopes
  scope :ordered,  ->           { order(id: :desc) }
  scope :del_fono, -> ( fono )  { where(:fono => fono) }

  
  after_commit -> { broadcast_replace_to "iconos", partial: "reportes/fonos", locals: { reporte: self }, target: "fonos" }

  private

  def sanitiza_fono
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


  #envia un mensaje de "Este es mi número" al Whatsapp del cliente. Usando el canal :client de facebook Waba
  def enviar_confirmar_fono
    unless self.confirmado
      ::Waba::Transaccion.new(:cliente).confirmar_fono self.fono, self.nombre
     # Turbo.visit("/reportes/id", { action: "replace" })
    end
  end

  #envía un formulario whatsapp por el canal colaborador de facebook waba, no  funciona
  def reservar
    ::Waba::Transaccion.new(:colaborador).say_flow_reservar self.fono, self.nombre
  end

end
