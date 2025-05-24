class Colaborador < ApplicationRecord
  self.table_name = 'colaboradores'
  include Linea
end
