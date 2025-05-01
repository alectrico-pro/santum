module Linea
  #La bitácora de los cálculos tiene un trato diferente en producción.
  #Se guarda en un registor del modelo circuito

  def reset_memoria
    $circuito_active_record_memoria =  Memo.new(self, true, "info") 
  end

  def ougai
#&%$--    @logger ||=  ::Ougai::Logger.new(STDOUT)
#    {3    return @logger
  end

  def logger
#    Logging::Logger.new(self.class)
 #   ::Ougai::Logger.new(STDOUT)
     ActiveSupport::Logger.new(STDOUT)
  end

  def linea
  #   ::Ougai::Logger.new(STDOUT)
   # Logging::Logger.new(self.class
    ActiveSupport::Logger.new(STDOUT)
  end

  def memoria
    if not $circuito_active_record_memoria
    #  Logging::Logger.new(self.class)
#   -   ::Ougai::Logger.new(STDOUT)
      ActiveSupport::Logger.new(STDOUT)

    else
      $circuito_active_record_memoria
    end
  end


end

