module Encuentra
  def self.presupuesto( fono )
    return ::Electrico::Presupuesto
           .no_pagado
           .efimero
           .no_realizado
           .vigente
           .find_by(:fono => fono )
  end

  def self.presupuesto_comercial( fono )
    return ::Electrico::Presupuesto
           .comercial
           .no_pagado
           .efimero
           .no_realizado
           .vigente
           .find_by(:fono => fono )
  end

end
