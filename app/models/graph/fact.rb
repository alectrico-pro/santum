require_relative './solicitud/base.rb'
module Graph
  class Fact
    include Linea

    attr_reader   :is_object
    attr_reader   :is_solicitud

    attr_accessor :params
    attr_reader   :id
    attr_accessor :uml
    attr_accessor :input
    attr_accessor :output
    attr_accessor :object
    attr_accessor :presupuesto
    attr_accessor :solicitud
    attr_accessor :appender
    attr_accessor :contacts
    attr_accessor :messages
    attr_accessor :error

    def save!
    end

    def procesa( fono, mensaje_id, publico)
      @object.procesa( fono, mensaje_id, publico)
    end

    def initialize( params=nil, input=nil, output=nil, solicitud=nil, appender=nil )

      @input    = input
      @ouput    = output
      @appender = appender
      @contacts = []
      @messages = []


      params =  ActiveSupport::HashWithIndifferentAccess.new(params)

      linea.info params.inspect
      hash   =  ActiveSupport::HashWithIndifferentAccess.new

      if params.nil?
        raise "Param es nil en Graph::Fact.inititalize"
      else
     
	#Esto ocurre en pruebas, supongo que debido a que uso Threads 
        #usr/local/bundle/gems/activesupport-5.0.7.2/lib/active_support/dependencies.rb:513:in `load_missing_constant': Unable to autoload constant Graph::Solicitud::Base, expected /myapp/app/models/graph/solicitud/base.rb to define it (LoadError)
      if params['error']
        hash['data'] = params['error'].to_json
        @error             = Graph::Error.json_create(hash)
          #inea.info "@error --"
      end


      hash['data']       = params.to_json

        #el mismo hash puede serviir para generar un objeto graph
        #o una solicitud graph
        #la diferencia es que las solicitudes son el código
        #que uno genera desde Waba::Transaction para 
        #conseguir cosas en Facebook y no tiene sentido
        #responder a ellas.
        #De todas maneras se anotan para un histórico
        #El cual es necesario para un chat futuro
        #linea.info "hash es:"
        #linea.info hash.inspect

        @object            = Graph::Object.json_create(hash)
        #edisfile<< @object if @object&.id

        #linea.info "objeto es:"
        #linea.info @object.inspect

        #linea.info "id de objeto es:"
        #linea.info @object.id

        #esto siginifica que debe ser llamado cuando se tenga el número
        #de solicitud, lo que es posterior al envío en Waba::Transaccion
        #Debe ser llamado así
        #Para que en los params aparezca el id asignado en Waba::Transaccion.send
        #Este id es generado como respuesta al envío del request
        #  fact = Graph::Fact.new( body.merge('id': id ) )

        #wip
        if params.has_key?( "id" )
          linea.info "Se creará una solicitud en Fact.init"
          @solicitud         = Graph::Solicitud::Base.json_create(hash)
        end

        if @object.object.nil?
          @is_object    = false
          @is_solicitud = true
        else
          @is_object    = true
          @is_solicitud = false
        end

       #@is_object    = (not @object.nil?)
       #@is_solicitud = ( not @solicitud.nil? )

        #redisfile<< @solicitud if @solicitud

        #unless params['presupuesto'].nil?
        #  hash['data']     = params['presupuesto'].to_json
        #  @presupuesto     = Graph::Object.json_create(hash)
        #end

        #contacts_data  = params['contacts']
        #if contacts_data&.any?
        #  contacts_data.each do |contact_data|
        #    contact_json = {'data'=> contact_data.to_json}
        #    contact = ::Graph::Contact.json_create(contact_json)
         #   @contacts << contact
        #  end
        #end

        #messages_data  = params['messages']
        #if messages_data&.any?
        #  messages_data.each do |message_data|
        #    message_json = {'data'=> message_data.to_json}
        #    message = ::Graph::Message.json_create(message_json)
        #    @messages << message
        #  end
        #end
        #linea.info "Self es:"
        #linea.info self.inspect
        return self 
      end

    end

    def es_para_mi?
      true
    end

    def from
      @object.from
    end

    #Este es un atajo de interpretación libre para construir umls en la agenda
    def payload
      return @object.payload if @object.payload.class == String
      @object.payload.respond_to?(:first) ? @object.payload.first : @object.payload
    end

    def id
      if @is_object
        @object.id 
      else
        nil
      end
   end

    def to
      @object.to
    end

    def tipo
      @object.tipo
    end

    def get_message
      @object.get_message
    end

    def put
      fact_format = @object&.send(:put)
      return fact_format
    end

    def monito(redisfile=nil)
      raise "redisfile es nil en monito de ::Graph::Fact" if redisfile.nil?
      @object&.send(:monito, redisfile)
      @solicitud&.send(:monito, redisfile)
    end


    def eco
      begin
        ::Waba::Transaccion.new(:admin).say_hola( C.fono_jefe, 'from: ' + self.from + '\n' + self.get_message  )
        return true
      rescue StandardError => e
        linea.error e.message
        puts e.message
        return false
      end
    end

  end
end
