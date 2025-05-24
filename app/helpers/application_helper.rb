# frozen_string_literal: true

module ApplicationHelper
  include Linea

  def render_turbo_stream_flash_messages
    turbo_stream.prepend 'flash', partial: 'layouts/flash'
  end

  def current_fono
    cookies.encrypted[:prueba]='prueba'
    if cookies.encrypted[:prueba] == 'prueba'
      linea.info "Las cookies funcionan en este dispositivo"
    end
    linea.info "current_fono"
    linea.info cookies.encrypted[:current_fono] 
    cookies.encrypted[:current_fono]  
  end

end
