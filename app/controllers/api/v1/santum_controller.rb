
#E#ste controaldor interfacea a la app santa en developoer facebook
module Api
  module V1
    class SantumController < V1Controller

      include Linea
      include Biblioteca::Mensajeria
      include CrearUsuario


      def verifica params
        linea.info "En verifica"
        es_challenge = false
        modo      = santum_params['hub.mode']
        challenge = santum_params['hub.challenge']
        token     = santum_params['hub.verify_token']
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
        if santum_params['hub.mode'] == 'subscribe'
          verifica santum_params
        else
          ::Waba::Webhook.new( santum_params )
          unless performed?
            render plain:  "ok" , status: :ok
          end
        end 
      end


      private

      def santum_params
        params.require(:santum).permit(entry: [changes: [value: [statuses: [:status], contacts: [profile: [:name]], metadata: [:display_phone_number], messages: [:text,:id,:timestamp,:from,:type, video: [:caption,:sha256,:id,:mime_type], image: [:caption,:sha256,:id,:mime_type], location: [:name,:address,:longitude,:latitude,:url], order: [:catalog_id, product_items: [:product_retailer_id,:quantity,:item_price,:currency]], context: [:id, :from], interactive: [:type, button_reply: [:id, :title]], button: [:payload,:text],text: [:body]]]]])
      end

    end
  end
end
