 module Api
    module V1
      class WebhookController < Api::V1Controller

        include Linea
        include Biblioteca::Mensajeria
        include CrearUsuario


        def verifica params
          linea.info "En verifica"
	  linea.info waba_params.inspect
          es_challenge = false
          modo      = waba_params['hub.mode']
          challenge = waba_params['hub.challenge']
          token     = waba_params['hub.verify_token']
          linea.info "Token a verificar es:"
          linea.info token

          linea.info "Token en Waba"
          linea.info WabaCfg.token_de_verificacion


          if modo == 'subscribe' and token == WabaCfg.token_de_verificacion.to_s
            linea.info "Es challenge"
            linea.info "Se devolverá"
            linea.info challenge
            es_challenge = true
            render plain:  challenge , status: :ok  
          else
            linea.info "No es challenge"
            render json: { :Error => "El acceso no está permitido!" }, status: :not_found  
          end
        end

        #endpoint para flows con contenido dinámico
        def flows
          linea.warn "En flow"
          linea.info "waba_params es:"
          linea.info waba_params.inspect
          ::Waba::Flow.new( presupuesto_params )
          unless performed?
            respond_to do |format|
              format.json { render json: { :status => :ok  } }
            end
          end 
        end

        def webhook
          linea.warn "En webhook"
	  linea.info "waba_params es:"
	  linea.info waba_params.inspect
          if presupuesto_params['hub.mode'] == 'subscribe'
            verifica presupuesto_params
            return
          else
            #Tests if render or redirect has already happened.
            ::Waba::Webhook.new( presupuesto_params )
            unless performed?
              respond_to do |format|
                format.json { render json: { :status => :ok  } }
              end
              return
            end
          end 
        end


	private

        def presupuesto_params
          params.permit!
        end

      end
    end
  end
