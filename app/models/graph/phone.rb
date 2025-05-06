module Graph
  class Phone
    attr_accessor :phone
    attr_accessor :wa_id
    attr_accessor :type

    def initialize(phone='', wa_id='', type='')
      @phone = phone
      @wa_id = wa_id
      @type  = type
    end

    def save!
    end

    def to_json(*a)
      data = {
        'phone' => @phone,
        'wa_id' => @wa_id,
        'type'  => @type }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      n = ::Graph::Phone.new(
        attrs['phone'],
        attrs['wa_id'],
        attrs['type'] )
    end

    def put
      " (phone (phone #{@phone}) (wa_id #{@wa_id}) (type #{@type}) )"
    end

    def monito(wa_id)
      " (phone (wa_id #{wa_id}) (phone #{@phone}) (wa_id #{@wa_id}) (type #{@type}) )"
    end


  end
end
