module Graph
  class Item
    attr_accessor :product_retailer_id
    attr_accessor :quantity
    attr_accessor :item_price
    attr_accessor :currency

    def initialize(product_retailer_id='', quantity=0, item_price=0, currency='CLP')
      @product_retailer_id = product_retailer_id
      @quantity            = quantity
      @item_price          = item_price
      @currency            = currency
    end

    def save!
    end

    def to_json(*a)
      data= {
              'product_retailer_id'   => @product_retailer_id,
              'quantity'              => @quantity,
              'item_price'            => @item_price,
              'currency'              => @currency
      }
      { 'json_class' => self.class.name,
            'data'   => data.to_json(*a)  }
    end 

    def self.json_create(o)
      attrs=JSON.parse(o['data'], :quirks_mode => true )
      n=::Graph::Item.new(
                             attrs['product_retailer_id'],
                             attrs['quantity'],
                             attrs['item_price'],
                             attrs['currency']
      )
    end

    def put(file_handle=nil, msg_id=nil)
      fact_format = " (item (product_retailer_id #{@product_retailer_id}) (quantity #{@quantity}) (item_price #{@item_price}) (currency #{@currency}) "
      unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end
      fact_format += ' )'
      if file_handle
        file_handle.puts fact_format
      end
    end
  end
end
