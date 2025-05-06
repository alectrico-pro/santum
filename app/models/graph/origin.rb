module Graph
  class Origin
    attr_accessor :type

    def initialize(type='')
      @type    = type
    end

    def save!
    end

    def to_json(*a)
      data= {'type' => @type }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      n=::Graph::Origin.new(attrs['type'])
    end

    def put(conversation_id=nil)
      raise "conversation_id nil en Graph::Origin" if conversation_id.nil?
      " (origin (conversation_id #{conversation_id}) (type #{@type})) "
    end
  end
end
