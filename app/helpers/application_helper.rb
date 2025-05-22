# frozen_string_literal: true

module ApplicationHelper
  include Linea

  def render_turbo_stream_flash_messages
    turbo_stream.prepend 'flash', partial: 'layouts/flash'
  end

  def current_user
    linea.info "current_user"
    linea.info     cookies.encrypted[:user_id] 
    cookies.encrypted[:user_id]  
  end

end
