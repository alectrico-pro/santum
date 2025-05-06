module Graph
  #Nota: Cuando  @from="447710173736", es envío de Facebook para validar el número de whatsapp
  class Text
    attr_accessor :body

    def initialize(body=nil)
      @body = body.gsub(' ','-')
    end

    def save!
    end

    def to_json(*a)
      data = { 'body' => @body }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      body = attrs['body']
      n = ::Graph::Text.new(body)
    end

    def put(msg_id=nil)
      fact_format = ' (text '
      fact_format +=  " (body #{@body})"
      unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end
      fact_format += ' )'
    end

  end
end
