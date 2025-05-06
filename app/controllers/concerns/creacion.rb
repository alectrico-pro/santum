  #Controla la creación de presupuestos
  class Creacion
    include Linea
    #No la puedo usar en config/initialize porque en ese momento no están definias las clases User, Ges...
    #Son las clases que se permiten durante la creación de presupuestos.Es una medid de seguridad adicional
    CLASES_PERMITIDAS=[ ::User, Gestion::Usuario, Solicitud]
 
    #Sete los valores iniciales de repositorio, puerto y presupuesto
    def initialize repositorio, puerto
      @repositorio = repositorio
      @puerto      = puerto
    end

    #crea una instanacia sin id y la devuelve indizada con un key, en un hash
    def new clase, params
      objetos = {}
      CLASES_PERMITIDAS.select{ |e| e == clase }.each do |clase|
        objeto = clase.new( params.select{ |p|  p.in?( clase.new.attributes )}.except('id'))
        objetos.store( objeto.class.to_s.demodulize.downcase.to_sym, objeto)
      end
      return objetos
    end

    #crea una instancia sin id y la devuelve como objeto
    def nueva_instancia clase, params

      CLASES_PERMITIDAS.select{ |e|
         e.to_s == clase }.each do |clase|
        objeto = clase.new( params.select{ |p| p.in?( clase.new.attributes.merge( {"password" => "no-importa"} ))}.except('id'))
        return objeto
      end
    end

    #atributos_hash={:user => {:id => 1, :name => "nombre" ....})
    #crea todas las instancias permitidas. No las guarda.
    #Se usa para verificar los párametros que ingreso el usuario
    #Durante la cración de presupuestos
    def crear_instancias ( atributos_hash )
      resultado = { }
      atributos_hash.each{ | id, params | 
        instancia = nueva_instancia( id.to_s.titleize.gsub(' ','::').constantize.to_s, params )
        resultado.store( id , instancia )
      }

      return resultado
    end

    #Junta todos los objetos si todos son válidos 
    def asociar_instancias( instancias ) 
      begin

        #genera los id que necsitaré más adelante
        instancias.each{|i|
          instancias[i.first].save! if instancias[i.first].valid? }

        #hago las conexiones
        instancias[:gestion_usuario].user_id        = instancias[:user].id
        instancias[:solicitud].gestion_usuario_id = instancias[:gestion_usuario].id
        instancias.each{|o|
          instancias[o.first].save!
        } #Esto actualiza los links externos
        resultado = :ok
      rescue StandardError => e
        resultado = :fail
      end      

      if resultado == :ok
        instancias.select{|o|
        instancias[o].valid?}.count == instancias.count
      else
        resultado = :error
      end     

      redirecciona resultado if @puerto
 
      return( (resultado == :ok) ? true : false )
      
    end

    def redirecciona resultado
      case resultado
      when :ok
        @puerto.muestra_ventana_edit params
      when :fail
        @puerto.muestra_ventana_new params
      when :error
        @puerto.muestra_ventana_error
      end
    end

    def get_format_errors
      @format_errors
    end
  end
