class Graph::Redisfile < Redis
  #mision: Funciona cuando redis tenga errores
  #
  #Crea soporte de datos en disco Redis
  #o en modo local (local es solo para test)
  #Redis es un servicio en producción que
  #guarda en memoria
  #el comando << permite usar indistintamente uno u otro
  #los comandos <<, puts y sets con casi sinómimos
  
  def initialize

   # linea.info "En initialize de ::Graph::Redisfile"
    #
   # if ENV['REDIS_URL'].present? 
   #   if Rails.env.test? or Rails.env.development?
   #     @redis = Redis.new(host: "redis")
   #   elsif Rails.env.production?
   #     if ENV['REDIS_URL'].present?
   #       @redis = Redis.new(host: "redis.service.local")
   #     end
   #   end
   # end
    #Detectando si es efectivo que @redis está configurado"
    begin
      if @redis.nil?
        file = File.open( './monito-facts.txt', 'w' )
        file.close
      end
    rescue 
      linea.error "No se pudo abrir archivo local en Graph::Redisfile initialize"
    end
    return self

    #Se abre un archivo para para que se pueda usar 
    #en clips. es solo copiarlo a monito_graph
    #Y luego ejecutar make monito
    #Aquí se abre con w,
    #En los otros métodos de Redifile se usa con 'a'
    #Eso es para permitir que se agregue los hechos
    #En cada llamado de <<, set o puts
    #
  end

  def puts( value )
    #set('obj', object)
    self << value if value
  end

  def get(a_key)
    @redis&.get(a_key)
  end

  def inspect
    @redis&.inspect
  end

  def <<( value )
    linea.info "lpush:"
    begin 
      linea.info @redis&.lpush('1', value )
    rescue StandardError => e
      linea.info e.inspect
      linea.info @redis&.inspect
    end
  end

  #set usa un método dado de REdis para no
  #tener que lidiar con toda la complejidad
  #de momento...
  def set( key, value )
    #La llave debe se numérica, incluso puede ser hexadecimarl
    #Si uso fa me lo acepta, incluso fac, pero no me acepta fact
    #porque t no es un caracter hexadecimal. Eso es lo que me
    #parece sin haber usado un tutorial de REdis
    #Tambíen acepta contantes de clases de objectos. Eso es más confuso
    #pero creo que en esencia las constantes son números
    #::Graph::Fact funciona pero no significa que value sea de esa clase
    #Solo es un número para los fines de Redis
    begin
      @redis&.set(key, value)
      unless value.nil? or value.empty?
        obj = self.get(value.class)
        #linea.info "En Redis se grabó:"
        linea.info obj.inspect
      else
        #linea.warn "En Redis value no se grabó. Empty on Redifile.set"
      end

    rescue StandardError => e
      linea.error e.inspect
      linea.warn "No se pudo interactuar con el servidor REdis"
      linea.info self.public_methods
      linea.info "Se usará el archivo monito-facts.txt"
      file = File.open( './monito-facts.txt', 'a' )
      file << value
      file.close
    end
    return self
  end


end
