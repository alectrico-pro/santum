module Graph
  class Context
    attr_accessor :from
    attr_accessor :id
    attr_accessor :referred_product

    def initialize(from='', id='', referred_product=nil)
      @from             = from
      @id               = id
      @referred_product = referred_product
    end

    def save!
    end

    def to_json(*a)
      data = {
        'from' => @from,
        'id'   => @id,
        'referred_product_id' => @referred_product_id    }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
   

    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )

      unless attrs['referred_product'].nil?
        referred_product_json = {"json_class" => "Graph::ReferredProduct",
                                       'data' => attrs['referred_product'].to_json}

        referred_product = ::Graph::ReferredProduct.json_create(referred_product_json)
      end

      n = ::Graph::Context.new(attrs['from'],
                               attrs['id'],
                               referred_product  )
    end

    def monito(file_handler=nil, msg_id=nil)
      raise "file_handler nil en monito de context" if file_handler.nil?
      fact_format = " (context (id #{@id}) (from #{@from})"
      unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end
      file_handler.puts @referred_product&.send(:put, @id)
      fact_format += ' )'
    end

    def put(message_id=nil)
      fact_format = " (context (id #{@id}) (from #{@from})"
      unless message_id.nil?
        fact_format += "(message_id #{message_id}) "
      end
      contenido = @referred_product&.send(:put)
      unless contenido.blank?
        fact_format += contenido
      end
      fact_format += ' )'
    end

  end
end
