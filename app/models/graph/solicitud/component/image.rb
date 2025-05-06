module Graph
  module Solicitud
    class Component
      class ::Graph::Solicitud::Component::Image  < ::Graph::Solicitud::Component
        attr_accessor :type
        attr_accessor :image
        def initialize(image=nil)
          @type  = "image"
          @image = image
        end

        def self.json_create(o)
          attrs = JSON.parse(o['data'])
          Solicitud::Language.new(attrs['code'])
        end
      end
    end
  end
end
