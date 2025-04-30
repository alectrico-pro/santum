class Comentario < ApplicationRecord
  belongs_to :reporte
  broadcasts_to :reporte
end
