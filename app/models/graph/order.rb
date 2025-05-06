module Graph
  class Order
    attr_accessor :catalog_id
    attr_accessor :product_items
    attr_accessor :text

    def initialize(catalog_id='', product_items=[], text='')
      @catalog_id     = catalog_id
      @product_items  = product_items
      @text           = text
    end

    def procesa
      linea.info "En procesa de Order"
      linea.info "No hacer nada"
    end

    def save!
    end

    def to_json(*a)
      data= {
              'catalog_id'     => @catalog_id,
              'product_items'  => @product_items,
              'text'           => @text
      }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)

      attrs=JSON.parse(o['data'], :quirks_mode => true )

      items = attrs['product_items']
      product_items = []
      if items&.any?
        items.each do |item_data|
          item_json = {'data' => item_data.to_json}
          item = ::Graph::Item.json_create(item_json)
          product_items << item
        end
      end

      n=::Graph::Order.new(
                             attrs['catalog_id'],
                             product_items.nil? ? '' : product_items,
                             attrs['text']
      )
    end
    def puts(file_handler, msg_id=nil)
      fact_format = " (order (catalog_id #{@catalog_id})"

      unless msg_id.nil?
        fact_format += " (msg_id #{msg_id}) "
      end

      unless @text.blank?
        fact_format += " (text #{@text})"
      end
      @product_items.each do |i|
        i&.send(:put, file_handler, msg_id)
      end
      fact_format += ' )'
    end


    def put
      fact_format = " (order (catalog_id #{@catalog_id})"

      unless @text.blank?
        fact_format += "(text #{@text})"
      end
      @product_items.each do |i|
        contenido = i&.send(:put)
        unless contenido.blank?
          fact_format += contenido
        end
      end
      fact_format += ' )'
    end
  end
end
