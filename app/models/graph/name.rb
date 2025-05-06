module Graph
  class Name
    attr_accessor :first_name
    attr_accessor :formatted_name

    def initialize(first_name='', formatted_name='')
      @first_name     = first_name
      @formatted_name = formatted_name
    end

    def save!
    end

    def to_json(*a)
      data = {
        'first_name'     => @first_name,
        'formatted_name' => @formatted_name }

      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      n = ::Graph::Name.new(
        attrs['first_name'],
        attrs['formatted_name'] )
    end

    def put
      " (name (first_name #{@first_name.parameterize}) (formatted_name #{@formatted_name.parameterize}) )"
    end

  end
end
