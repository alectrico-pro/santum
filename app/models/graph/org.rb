module Graph
  class Org
    attr_accessor :company

    def initialize(company='')
      @company     = company
    end

    def save!
    end

    def to_json(*a)
      data = {
        'company'     => @company}

      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      n = ::Graph::Org.new(
        attrs['company'] )
    end

    def put
      " (org (company #{@company}))"
    end

    def monito(wa_id=nil)
      " (org (wa_id #{wa_id}) (company #{@company}))"
    end



  end
end
