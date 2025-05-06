require 'paypal-sdk-rest'
include PayPal::SDK::REST
#Este controlador era para acompañar el tipo de pago de paypal del lado del cliente pero no fue usado porque se prefirió el de REST API, el cual se usa en 
#iframe/payments
module Api
  module V1
    module Paypal
      class PaymentsController < PaypalController


	def client_token
	  gateway = Braintree::Gateway.new(
	    :access_token => "access_token$sandbox$567c4wqvgtqycnn2$7d4d77aad714feb8bd4323472ab8dd92"
	  )

          gateway.client_token.generate
	end

        #Suma cada precio de items y obtiene un total neto
        def subtotalForCart
          @orden = ::Comercio::Orden.find_or_create_by(:amp_cliente_id => params[:amp_cliente_id])
          respond_to do |format|
            if request.headers['Origin']

              @origen = params[:__amp_source_origin]
              response.headers['Access-Control-Allow-Origin'] = @origen

              format.json {}
            end
          end
        end



	def execute_pago
           
	end

	def create_pago
          respond_to do |format|
            if true #request.headers['Origin']

              @origen = params[:__amp_source_origin]
              response.headers['Access-Control-Allow-Origin'] = @origen
             
#	      raise session[:uid].inspect
#      amp_cliente_id = params[:amp_cliente_id] #No sirve porque fue llamado desde un iframe (es algo que no usa amp)
	      #
#      amp_cliente_id = ENV["CLIENT_ID"] #no debiera funcionar en el cache
#      current_user.perfil_amp_cliente_id #no funciona en el iframe

#              orden = ::Comercio::Orden.find_by(:amp_cliente_id => amp_cliente_id)
	      @orden = ::Comercio::Orden.last
	      if @orden
                @orden.touch              
	      else
                format.json { render json: ["Error buscando orden para cliente #{amp_cliente_id}"],status: :unprocessable_entity }
	      end

              case @origen 
              when C.iframe

		payment = PayPal::SDK::REST::Payment.new({
		  :intent =>  "sale",
		  # Set payment type
		  :payer =>  {
		    :payment_method =>  "paypal"
		  },

		  # Set redirect urls
		  :redirect_urls => {
		    :return_url =>  C.cache + "/checkout_success",
		    :cancel_url =>  C.cache + "/checkout"
		  },

		  # Set transaction object
		  :transactions =>  [{

		    # Items
		    :item_list => {
		      :items => [{
			:name => "item",
			:sku => "item",
                        :price => @orden.total,
			:currency => "USD",
			:quantity => 1
		      }]
		    },

		    # Amount - must match item list breakdown price
		    :amount =>  {
		      :total =>  @orden.total,
		      :currency =>  "USD"
		    },
		    :description =>  "payment description."
		  }]
		})
                if payment.create
		  format.all {
                  redirect_url = payment.links.find{|v| v.rel == "approval_url" }.href
                  redirect_to redirect_url
                  }
                  #ormat.json { render json: payment, status: :ok }		  
                else
                  format.json { render json: payment.error,status: :unprocessable_entity }
                end
              else
                format.json { render json: @orden, status: :unprocessable_entity }        
              end
            else
              format.json { render json: ["no fue especificado header: 'Origin'"], status: :unprocessable_entity }
            end
          end
	end
      end
    end
  end
end
=begin
          respond_to do |format|
            format.json do
	      if request.headers['Origin']
		case @origen
		when C.iframe
                   
		  response.headers['Access-Control-Allow-Origin'] = @origen

		  payment = Payment.new({
		    :intent =>  "sale",
		    # Set payment type
		    :payer =>  {
		      :payment_method =>  "paypal"
		    },

		    # Set redirect urls
		    :redirect_urls => {
		      :return_url =>  "#{checkout_success_path}",
		      :cancel_url => "#{checkout_success_path}"
		    },

		    # Set transaction object
		    :transactions =>  [{

		      # Items
		      :item_list => {
			:items => [{
			  :name => "item",
			  :sku => "item",
			  :price => @orden.total,
			  :currency => "CLP",
			  :quantity => 1
			}]
		      },

		      # Amount - must match item list breakdown price
		      :amount =>  {
			:total =>  "10",
			:currency =>  "USD"
		      },
		      :description =>  "payment description."
		    }]
		  })
		  # Create payment
                  
		  if payment.create
                    @payment = payment
		    amp_cliente_id = params[:amp_cliente_id]
		    @orden = ::Comercio::Orden.find_by(:amp_cliente_id => amp_cliente_id)

		    # Capture redirect url
		    redirect_url = payment.links.find{|v| v.rel == "approval_url" }.href
	    #       redirect_to redirect_url
		    #
		    # REDIRECT USER TO redirect_url
                    format.json { render json: payment, status: :ok }

		  else
                    format.json { render json: payment.errors, status: :unprocessable_entity }
		    #logger.error payment.error.inspect
		  end
		end
	      end
	    end
          end
	end
      end
    end
  end
end
=end
