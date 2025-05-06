#Biblioteca de comercio
module Biblioteca
  module Pago
    def onepay_datos_pago_to_paypal datos_pago_json, sku='', occ=''

      onepay_payment =  ::Comercio::OnepayPayment.json_create(
                           datos_pago_json
                        )

      payer_info      = ::Comercio::PayerInfo.new(
                          "#{occ}@alectrico.cl",
                          "User_#{occ}",
                          '',
                          '',
                          '',
                          56
                        )
      item            = ::Comercio::Item.new(
                          sku ,
                          onepay_payment.descripcion,
                          1,
                          onepay_payment.amount.to_i,
                          ''
                        )
      item_list       = ::Comercio::ItemList.new(
                          [ item ]
                        )
      payer           = ::Comercio::Payer.new(
                          payer_info
                        )
      amount          = ::Comercio::Amount.new(
                          onepay_payment.amount.to_i
                        )
      transaction     = ::Comercio::Transaction.new(
                          item_list,
                          amount
                        )

                        ::Comercio::Payment.new(
                          onepay_payment.payment_id,
                          payer,
                          [ transaction]
                        )


    end

   #ONEPAY fromat to PAYPAL format
    #De esta forma se normaliza todo al formato Paypal
    def webpay_to_paypal pedido_json, result_json
      pedido = ::Comercio::Webpay::Pedido.json_create( pedido_json )
      amount          = ::Comercio::Amount.new(
                          pedido.amount
                        )

      transaction     = ::Comercio::Transaction.new(
                          pedido.buy_order,
                          amount
                        )


      ::Comercio::Payment.new(
          nil,
          nil,
          [ transaction ]
        )

    end

   #ONEPAY fromat to PAYPAL format
    #De esta forma se normaliza todo al formato Paypal
    def onepay_to_paypal carro_json, result_json

      payer_info      = ::Comercio::PayerInfo.new(
                          '',
                          '',
                          '',
                          '',
                          '',
                          56
                        )

        payer           = ::Comercio::Payer.new(
                          payer_info
                        )

       carro  = ::Comercio::OnepayCarro.json_create(
                         carro_json
                       )

       result = ::Comercio::OnepayResult.json_create(
                         result_json
                        )

       item_list       = ::Comercio::ItemList.new(
                          []
                        )

       if carro.items.any?
         carro.items.each do |it|
                    item = ::Comercio::Item.new(
                            it['additional_data'] ,
                            it['descripcion'],
                            it['quantity'],
                            it['amount']
                          )
               item_list.items.push( item )
         end
       end
    amount          = ::Comercio::Amount.new(
                          carro.items.sum{|a| a['amount']*a['quantity']}
                        )

       transaction     = ::Comercio::Transaction.new(
                          item_list,
                          amount
                        )

                        ::Comercio::Payment.new(
                          result.occ,
                          payer,
                          [ transaction ]
                        )
    end


  #KHIPU format to PAYPAL format
    #Esto ya no se usa, pues sienpre se guardan datos_pago en formato
    #::Comercio::Payment
    def khipu_to_paypal datos_pago_json, sku=''
      #El formato de payment que entrega kHIPU está orientado a una transacción bancaria, así que carece del número de producto: sku. Por eso debe proveerse desde afuera.
      khipu_payment   = ::Comercio::KhipuPayment.json_create(
                          datos_pago_json
                        )

      if khipu_payment.payment_id.nil?
        #Los datos no estaban en formato khipu
        #Se asumirá que están en formato Comercio::Payment
        return ::Comercio::Payment.json_create(
                 datos_pago_json )
      end

      payer_info      = ::Comercio::PayerInfo.new(
                          khipu_payment.payer_email,
                          khipu_payment.payer_name,
                          '',
                          '',
                          '',
                          56
                        )
      item            = ::Comercio::Item.new(
                          sku ,
                          khipu_payment.subject,
                          1,
                          khipu_payment.amount.to_i,
                          khipu_payment.currency
                        )
      item_list       = ::Comercio::ItemList.new(
                          [ item ]
                        )
      payer           = ::Comercio::Payer.new(
                          payer_info
                        )
      amount          = ::Comercio::Amount.new(
                          khipu_payment.amount.to_i
                        )
    transaction     = ::Comercio::Transaction.new(
                          item_list,
                          amount
                        )

                        ::Comercio::Payment.new(
                          khipu_payment.payment_id,
                          payer,
                          [ transaction]
                        )
    end


=begin
    #PAYPAL External to Internal format
    def self.to_comercio_payment_original paypal_payment
      extend Linea
      linea.info "En ::ComprarAhora.to_comercio_payment"

      shipping_address= ::Comercio::ShippingAddress.new(
                         paypal_payment.payer.payer_info.shipping_address.line1,
                         paypal_payment.payer.payer_info.shipping_address.line2,
                         paypal_payment.payer.payer_info.shipping_address.phone,
                         paypal_payment.payer.payer_info.shipping_address.country_code
                       )

      payer_info      = ::Comercio::PayerInfo.new(
                          paypal_payment.payer.payer_info.email,
                          paypal_payment.payer.payer_info.first_name,
                          paypal_payment.payer.payer_info.last_name,
                          shipping_address, 
                          paypal_payment.payer.payer_info.phone,
                          paypal_payment.payer.payer_info.country_code
                        )

      item_list  = ::Comercio::ItemList.new([ ])
      lista_item = paypal_payment.transactions.first.item_list.items

      lista_item.each do |it|
        item = ::Comercio::Item.new(
                            it.sku,
                            it.name,
                            it.quantity,
                            it.price,
                            it.currency
                         )
        linea.info "Item #{item.inspect}"
        item_list.items << item
      end

      payer           = ::Comercio::Payer.new(
                          payer_info
                        )

      transactions = []

      paypal_payment.transactions.each do |tr|
        amount          = ::Comercio::Amount.new(
                            tr.amount.total
                          )
        transaction     = ::Comercio::Transaction.new(
                            item_list,
                            amount
                          )
        transactions << transaction
      end

      payment         = ::Comercio::Payment.new(
                          paypal_payment.id,
                          payer,
                          transactions,
                        )
      return payment
    end
=end



  end
end
