class Comentario < ApplicationRecord
  belongs_to :reporte

  validates_presence_of :contenido
  validates :contenido, length: { in: 4..255}
  broadcasts_to :reporte
  #before_save :prepend_name

  #def prepend_name
  #  self.contenido = reporte.nombre + "--" + self.contenido
  #end
end
