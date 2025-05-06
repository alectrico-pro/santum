module Graph
  class Metadata
    attr_accessor :display_phone_number
    attr_accessor :phone_number_id

    def initialize(display_phone_number='', phone_number_id='')
      @display_phone_number = display_phone_number
      @phone_number_id      = phone_number_id
    end

    def save!
    end

    def to_json(*a)
      data= { 'display_phone_number' => @display_phone_number,
              'phone_number_id'      => @phone_number_id  }
      { 'json_class' => self.class.name,       
        'data' => data.to_json }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      n=::Graph::Metadata.new(attrs['display_phone_number'], attrs['phone_number_id'])
    end

    def put
      " (metadata (display_phone_number #{@display_phone_number}) (phone_number_id  #{@phone_number_id}))"
    end
    def monito(entry_id=nil)
      #raise "entry_id es nil" if entry_id.nil?
      " (metadata (entry_id #{entry_id}) (display_phone_number #{@display_phone_number}) (phone_number_id  #{@phone_number_id}))"
    end


  end
end
