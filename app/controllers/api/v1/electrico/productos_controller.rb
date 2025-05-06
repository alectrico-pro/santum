#Esto es el backend que usa designer.alectrico.cl
#designer alectrico.cl es una pagina amp
#Se usa para crear circuitos y encontrar el empalme adecuado
#
module Api
  module V1
    module Electrico
      class ProductosController < Api::V1::ElectricoController

        include Linea

	before_action :cors 
	skip_before_action :cors if Rails.env.test?
#        before_action :cache_config
        #Este es el feed de la lista de electrodomésticos en designer
        #Busca el presupuesto que esté asociado al dispositivo y muestra los electromésticos que lo componen
        #No está preocupado de averiguar si hay un usuario o no
        #Debiera cargar los electrodomésticos del usuario, para ello hay que avergiuar si hay algún usuario logado y luego averiguar si tiene algún prespuesto.
        #Entonces tendré dos presupuestos, el asociado al dispositivo y el pertenciente al usuario.
        #Deberé reemplazar el presupuesto asociado al dispositivo por el que trae el usuairo de cualquier otro dispositivo?
        #Se garantiza que cada usuario solo tenga un presupuesto por dispositivo, pero eso complica un poco, porque sí se permite que haya muchos presupuestos por usuario. Habrá que mostrar cuál es el presupuesto que quiere asociar al dispositivo antes de asignarlo al dispositiov
        #Será un menú de selector que aparecerá cuando un usuario se logge y no tenga un prespuesto en el dispositivo. Luego de efectuada la sección deberá desaparecer. No aparecerá más, porque desde ese momento habrá un prespuesto asociado al dispositivo, a no ser que se borre el dispositivo.
        def atencion
          respond_to do |format|
            format.json
          end
        end

        #marketplace es una variante de get para cuba
        #donde la tensión es de 110
        #y donde el objetivo es vender
        #por lo tanto debe haber información de stock y de precios
        #así como indicar las caracterísiticas
        #del producto
        def get
          expires_in 0.seconds, :public => false
          @presupuesto = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])
          @presupuesto = ::Electrico::Presupuesto.first unless @presupuesto
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          @potencia_total_industrial = 0
          @potencia_total_domiciliaria = 0
          @cargas = nil
          @potencia_bruta = 0
          @potencia_instalada = 0
          @fp_minimo = 0
          @is_total = 0
          @empalme_aereo_sugerido = nil
          @empalme_soterrado_sugerido = nil
          respond_to do |format|
            if @presupuesto
              #sanitizar los circuitos, 
              @presupuesto.circuitos.each{|c| c.delete unless c.cargas.count > 0 }
                factor_de_demanda = 0.35
                @potencia_total_industrial = @presupuesto.cargas.sum(&:get_p)
                @potencia_total_domiciliaria = @potencia_total_industrial > 3000 ? ((@potencia_total_industrial - 3000) * 0.35 + 3000) : @potencia_total_industrial
                @cargas = @presupuesto.cargas
                if @cargas.count >0
                  @tension           = 110
                  @potencia_bruta     = @presupuesto.cargas.sum(&:get_p)
                  @potencia_instalada = (@potencia_bruta > 3000) ? ((@potencia_bruta - 3000) * factor_de_demanda + 3000)  : @potencia_bruta
                  @fp_minimo          = @presupuesto.cargas.min{|a,b| a.get_fp <=> b.get_fp}.get_fp
                  @is_total           = @potencia_instalada/ (@tension * @fp_minimo )
                  @empalmes          = D::Empalmes.new
                  @candidatos        = @empalmes.get_nodos.select{ |a| a.interruptor >= @is_total and a.medio == "Aéreo" and a.no_fases == "Monofásico" and a.cumple_potencia_nominal?(@potencia_instalada)}
                  unless @candidatos.count > 0
                    @candidatos        = @empalmes.get_nodos.select{ |a| a.interruptor >= @is_total and a.medio == "Aéreo" and a.no_fases == "Trifásico" and a.cumple_potencia_nominal?(@potencia_instalada)}
                  end
                  @empalme_aereo_sugerido = @candidatos.first
                  @candidatos        = @empalmes.get_nodos.select{ |a| a.interruptor >= @is_total and a.medio == "Subterráneo" and a.no_fases == "Monofásico" and a.cumple_potencia_nominal?(@potencia_instalada)}
                unless @candidatos.count > 0
                  @candidatos        = @empalmes.get_nodos.select{ |a| a.interruptor >= @is_total and a.medio == "Subterráneo" and a.no_fases == "Trifásico" and a.cumple_potencia_nominal?(@potencia_instalada)}
                 end
                 @empalme_soterrado_sugerido = @candidatos.first
               end
               format.json {} #se usa json.builder en los subdirectorios de vistas
            else
               format.json {}
            end
          end
        end



        #usa una lista para mostar cuán llenos están los circuitos
        def ocupacion
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          expires_in 0.seconds, :public => false
          presupuesto = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])
           respond_to do |format|
             if presupuesto
               @circuitos = presupuesto.circuitos
               format.json {} #se usa json.builder en los subdirectorios de vistas
             else
               format.json { render json: {:items => []}}
             end
           end
        end

        def cart
          expires_in 0.seconds, :public => false
          if user_signed_in?
            @presupuesto = current_user.usuario.presupuestos.unscope(:order).last
          end
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          respond_to do |format|
            if @presupuesto
              @cargas = @presupuesto.cargas
              format.json {} #se usa json.builder en los subdirectorios de vistas
            else
              format.json { render json: {:items => []}}
            end
          end
        end

        def catalogo
          expires_in  1.month, :public => false
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          @maquetas = ::Electrico::MaquetaEquipo.all
          respond_to do |format|
            format.json 
          end
        end

        #Require rake prepara:designer
        #Borrar caches luego de que se agreguen nuevos Electrico::MaquetaEquipo
        #Estoy usando fifito como un marketplace
        #Entonces habrás MaquetaEquipos solo con el modelo markeplace
        #para que no salgan en designer
        def productos
          #xpires_in  1.month, :public => false
          expires_in 0.seconds, :public => false
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          @maquetas = ::Electrico::Producto.all
          #fresh_when(@maquetas)
          @yellow = @maquetas.yellow.fifo.all
          @blue   = @maquetas.blue.fifo.all
          
          @green = @maquetas.green.fifo.all
          @golden  = @maquetas.golden.fifo.all
          @coral = @maquetas.coral.fifo.all
          @red   = @maquetas.red.fifo.all
        #  @blue  = ::Electrico::MaquetaEquipo.order('p').select{ |c| c.p > 0 && (c.p <= BLUE_MAX)}
        #  @green = ::Electrico::MaquetaEquipo.order('p').select{ |c| c.p > BLUE_MAX && (c.p <= GREEN_MAX)}
        #  @gold  = ::Electrico::MaquetaEquipo.order('p').select{ |c| c.p > GREEN_MAX && (c.p <= GOLD_MAX)}
        #  @coral = ::Electrico::MaquetaEquipo.order('p').select{ |c| c.p > GOLD_MAX && (c.p <= CORAL_MAX)}
        #  @red   = ::Electrico::MaquetaEquipo.order('p').select{ |c| c.p > CORAL_MAX}

          respond_to do |format|
            format.json
          end
        end

        #Require rake prepara:designer
        #Borrar caches luego de que se agreguen nuevos Electrico::MaquetaEquipo
        def batteries
          expires_in  1.month, :public => false
          expires_in 0.seconds, :public => false
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

          @batteries = ::Electrico::Battery.all
          @blue   = @batteries.blue.fifo.all
          @green  = @batteries.green.fifo.all
          @golden = @batteries.golden.fifo.all
          @coral  = @batteries.coral.fifo.all
          @red    = @batteries.red.fifo.all

          respond_to do |format|
            format.json
          end
        end


        def servicios
          expires_in  1.month, :public => true
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          respond_to do |format|
            format.json
          end
        end


        def deleteElectrodomestico
          expires_in 0.seconds, :public => false

          @carga = ::Electrico::Carga.find_by(:id => params[:id])
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          circuito = @carga.circuito
          p = circuito.presupuesto
          p.touch
          p.save
          respond_to do |format|
            if @carga.delete
              circuito.update(:corriente_servicio => circuito.cargas.sum(&:get_i))
              @cargas = @carga.circuito.cargas
              format.json {}
            else
              format.json { render json: {:error =>  @carga.errors[:base]}, status: :unprocessable_entity }
            end
          end
        end

        def enviarSolicitud
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'

          linea.info "en enviarSolicitud"
          presupuesto = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id])
          resultado = false
          comprador = ::Gestion::Usuario.find_by(:amp_cliente_id => params[:amp_cliente_id])
          mayoristas_fono = Array.new

          presupuesto.orden.actualiza_totales

          if presupuesto
             presupuesto.update(:usuario => comprador) 
             presupuesto.cargas.each do |carga|
             mayorista = ::Gestion::Usuario.find_by(:id => carga.tipo_equipo.servicio.proveedor_id)
             mayoristas_fono << mayorista.fono
             resultado = ::Waba::Transaccion.new(:cliente).fifito_vale_de_mensajeria( presupuesto, carga, mayorista.fono )
             linea.info "Antes de llamar a ud_ha_solicitado"
             ::Marketplace::Mailer.ud_ha_solicitado( presupuesto ).deliver_now
             linea.info "Después de llamar a ud_ha_solicitado"

             linea.info "Antes de llamar a alguien_ha_solicitado"
             ::Marketplace::Mailer.alguien_ha_solicitado( carga, presupuesto, mayorista.email ).deliver_now
             linea.info "Después de llamar a alguien_ha_solicitado"
           end
          
           mayoristas_fono.uniq.each do |fono|
             ::Waba::Transaccion.new(:cliente).say_datos_bancarios( presupuesto, fono)
           end

          end

          respond_to do |format|
            if resultado and presupuesto  
              format.json { render json: {status: :success } }
            else
              format.json { render json: {status: 'Error Enviando Wabas' }, status: :unprocessable_entity  }
            end
          end
        end

        def dropFromCircuito
          expires_in 0.seconds, :public => false
          @carga = ::Electrico::Carga.find_by(:id => params[:id])
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          circuito = @carga.circuito 

          presupuesto = circuito.presupuesto
          presupuesto.touch
          presupuesto.save
          respond_to do |format|
            if @carga.delete
              if circuito
                circuito.update(:corriente_servicio => circuito.cargas.sum(&:get_i))

                #borro todos los servicios y los vuelvo a agregar pero solo los que
                #estén referidos por las cargas del proyecto
                presupuesto.orden.servicios.delete_all

                presupuesto.cargas.each do |carga|
                   servicio = carga.tipo_equipo.servicio
                   presupuesto.orden.servicios << servicio if servicio
                end
                presupuesto.save
                @cargas = @carga.circuito.cargas
              end

              format.json {}

            else	
              format.json { render json: {:error =>  @carga.errors[:base]}, status: :unprocessable_entity }
            end     		  
          end
        end

	      #Permite ver los circutos en un disposiivo diferente a aquel en el que fueron creados
        #Se puede incluso cambiar de un celular a otro, solo haciendo login y eligiendo sincronizar cuandos se le pregunte
        def syncFromRemote
          linea.info "En syncFromRemote"
          expires_in 0.seconds, :public => false
          @presupuesto_local = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id]) if params[:amp_cliente_id]
          linea.info "Hay un presupuesto local #{@presupuesto_local.inspect}"

          if user_signed_in? 
            linea.info "El usuario está logado"

            @presupuesto_remoto = current_user.usuario.presupuestos.unscope(:order).order(:updated_at).last
            linea.info "Se encontró un presupuesto remoto" if @presupuesto_remoto

            if current_user.member
              linea.info "El usuario es miembro"

              if @presupuesto_local
                linea.info "Hay un presupuesto local"

                if @presupuesto_remoto.amp_cliente_id != params[:amp_cliente_id]
                  linea.info "El presupuesto remoto está en otro dispositivo, lo he verificado con amp_cliente_id"
                  linea.info "El presupeusto remoteo tiene #{@presupuesto_remoto.circuitos.count} circuitos"

                  @presupuesto_remoto.circuitos.each do |c|
                    linea.info "Agregando el circuito #{c.inspect}"
                    @presupuesto_local.circuitos << c
                  end
                  @presupuesto_local.touch
                  @presupuesto_local.save

                  linea.info "Terminó de pasar circuitos, el presupuesto local tiene ahora #{@presupuesto_local.circuitos.count} circuitos"
                else
                  linea.info "El presupuesto remoto está en el mismo dispositivo"
                end
              else
                linea.info "No hay presupuesto local"
              end
            else
              #la syncronización es un solo sentido, se trae el ultimo presupuesto, cambiando el cliente_id de amp
              #Y si hay un presupuesto local se borra

              if @presupuesto_remoto.amp_cliente_id != params[:amp_cliente_id]
                @presupuesto_remoto.amp_cliente_id = params[:amp_cliente_id]
                @presupuesto_remoto.save!
                @presupuesto_local.destroy if @presupuesto_local
              end
            end
          end
          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
          respond_to do |format|
            if @presupuesto
              @cargas = @presupuesto.cargas
              format.json {} #se usa json.builder en los subdirectorios de vistas
            else
              format.json { render json: {:items => []}}
            end
          end
	end

        def addToCircuito

          response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
          response.headers['Access-Control-Allow-Credentials'] = true
          response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'


#                       cantidad = params[:quantity].to_i
#             for i in 1..cantidad
#               @carga = @circuito.cargas.create do |carga|
#               carga.tipo_equipo = tipo_equipo
#               cantidad          = 1
#             end

          linea.info "Cantidad en addToCircito es:"
          linea.info params[:quantity].to_i
          @circuito = ::Producter.new(amp_params.merge({'forro' => 'THHN'})).addToCircuito          
          presupuesto = @circuito.presupuesto

          if @circuito and @circuito.cargas.any? and presupuesto.present?

            unless presupuesto.orden
              linea.info "Creando orden"
              presupuesto.create_orden
            end

            #Agregar un servicio que corresponda a la última carga existente
            carga = @circuito.cargas.last
            suma = (presupuesto.precio.nil? ? 0 : presupuesto.precio)
            if carga and carga.tipo_equipo and carga.tipo_equipo.servicio
              linea.info "Agregando un servicio"
              servicio = carga.tipo_equipo.servicio
              presupuesto.orden.servicios << servicio 
              suma = suma + servicio.precio
            end #carga, tipo_equipo, servicio

            #describir el presupuesto enumerando los servicios que tiene
            nueva_descripcion = ''
            presupuesto.cargas.each do |carga|
              nueva_descripcion = nueva_descripcion + "| #{carga.cantidad} X " + carga.tipo_equipo.servicio.nombre
              presupuesto.update({:descripcion => nueva_descripcion, 
                                  :precio => suma,:es_comercio => true, 
                                  :es_electricidad => false})
            end #servicios.each

          end #circuito.cargas.any?

          respond_to do |format| 
            if @circuito and @circuito.cargas.any?
               @cargas = @circuito.cargas
               format.json {} #se usa json.builder en los subdirectorios de vistas
             else
               format.json { render json: {:error => "No se pudo crear circuito."}, status: :unprocessable_entity }
            end
          end
        end


        def addToCircuito_original
          linea.info "En addToCircuito"
         
          presupuesto = ::Electrico::Presupuesto.find_by(:amp_cliente_id => params[:amp_cliente_id]) if params[:amp_cliente_id]
          linea.info "Presupuesto es #{presupuesto.inspect}"
          
          linea.info "current-user es #{current_user.usuario.inspect}"
          if params[:amp_cliente_id] and presupuesto and user_signed_in? and current_user.usuario
            presupuesto.update(:usuario => current_user.usuario)
          end


          desistir = false
          if true  
            tipo_equipo =  ::Electrico::TipoEquipo.find_by(:id => params[:carga_id])
            linea.info "Tipo Equipo es #{tipo_equipo.id}"
            tipo_circuito = ::Electrico::TipoCircuito.find_by(:letras => params[:circuito])
            if tipo_circuito
              @presupuesto = ::Electrico::Presupuesto.find_or_create_by(:amp_cliente_id => params[:amp_cliente_id])
              @presupuesto.efimero = true
              if @presupuesto.save(:context => :designer)
                 linea.info "Presupuesto salvado exitosamente en contexto designer"
                 @circuito  = @presupuesto.circuitos.find_or_create_by(:tipo_circuito => tipo_circuito)  do |c|
                 c.largo = 10
                 c.grupo = "A"
              end
              linea.info "Circuito es #{@circuito.inspect}"
              cantidad = params[:quantity].to_i
              for i in 1..cantidad
                @carga = @circuito.cargas.create do |carga|
                carga.tipo_equipo = tipo_equipo
                cantidad          = 1
              end
            end
            linea.info "Calculando la corriente de servicio"
            @circuito.corriente_servicio = @circuito.cargas.sum(&:get_i)
            linea.info "Circuito #{@circuito.inspect}"
            p = @circuito.presupuesto
            p.touch
            p.save
	  end
	end
	    #Estrategia recomendada para igualar el identificador de usuario que usa google analytics y el que usa google para las páginas amp.
	    #Se toma el id que viene en el requeste en el parámetros ref_id, y se setea la cookie uid que se usó antes para extraer el parámetro clienteId, por lo tanto, se obtiene que params[:amp_cliente_id] tendrá el mismo valor que params[:ref_id] = amp_access o algo asaccess o algo así #  @circuitos = ::Electrico::Circuito.all
        response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
        response.headers['Access-Control-Allow-Credentials'] = true
        response.headers['Access-Control-Expose-Headers'] = 'AMP-Access-Control-Allow-Source-Origin'
      end

        respond_to do |format|
          if desistir
            format.json { render json: {:error => "Debe hacer login para agregar más electrodomésticos."}, status: :unprocessable_entity}
          else
            unless tipo_circuito
              format.json { render json: {:error => "No existe el tipo de circuito #{params[:circuito]}"}, status: :unprocessable_entity}
            else
              if @presupuesto.save(:context => :designer)
                @cargas = @circuito.cargas
                if @circuito.save
                  if @carga.save
                    @cargas = @circuito.cargas
                    format.json {} #se usa json.builder en los subdirectorios de vistas
                  else
                    format.json { render json: {:error =>  @carga.errors[:base]}, status: :unprocessable_entity }
                  end
                else
                  format.json {}
                end
              else
                format.json { render json: {:error =>  @presupuesto.errors}, status: :unprocessable_entity }
              end
            end
          end
        end
      end

  private
        def amp_params
          params.permit("color","quantity","circuito","carga_id", "amp_cliente_id")
        end

        def cid
          ref_id    = params[:ref_id].gsub!("'",'') if params[:ref_id]
          client_id = params[:amp_cliente_id] if params[:amp_cliente_id]
          if ref_id
            cid = ref_id
            cookies[:uid] = { value: ref_id, domain: ".#{C.domain}"} 
          end
          if client_id
            cid = client_id
       	  end
          return cid
        end
      end
    end
  end
end
