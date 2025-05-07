
#E#ste controaldor interfacea a la app santa en developoer facebook
module Api
  module V1
    class SantaController < V1Controller

      include Linea
      include Biblioteca::Mensajeria
      include CrearUsuario


      def verifica params
        linea.info "En verifica"
        es_challenge = false
        modo      = presupuesto_params['hub.mode']
        challenge = presupuesto_params['hub.challenge']
        token     = presupuesto_params['hub.verify_token']
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

      def webhook
        linea.warn "En webhook"
        if presupuesto_params['hub.mode'] == 'subscribe'
          verifica presupuesto_params
        else
          ::Waba::Webhook.new( presupuesto_params )
          unless performed?
            render plain:  "ok" , status: :ok
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
