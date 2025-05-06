module Graph
  class Conversation
    attr_accessor :id
    attr_accessor :origin

    def initialize(id='', origin=nil)
      @id      = id
      @origin  = origin
    end

    def save!
    end

    def to_json(*a)
      data= { 
            'id'       => @id,
            'origin'   => @origin
      }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )

      origin = nil
      unless attrs['origin'].nil?
        origin_json = {"json_class" => "Graph::Origin", 
                     'data' => attrs['origin'].to_json}

        origin = ::Graph::Origin.json_create(origin_json)
      end
      n=::Graph::Conversation.new(attrs['id'],
                             origin.nil? ? '' : origin)
    end

    def monito(status_id=nil, file_handler)
      raise "status_id nil en Graph::Conversation" if status_id.nil?
     fact_format = " (conversation (id #{@id})"
     fact_format += " (status_id #{status_id})"
     file_handler.puts  @origin&.send(:put, @id)
     fact_format += ' )'
    end


    def put
     fact_format = " (conversation (id #{@id})"
     contenido =  @origin&.send(:put, @id)
     unless contenido.blank?
       fact_format += contenido
     end
     fact_format += ' )'
    end

  end
end
