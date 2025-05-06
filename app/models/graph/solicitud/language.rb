module Graph
  module Solicitud
    class Language  < Base
      attr_accessor :code
      def initialize(code='')
        @code=code
      end

      def self.json_create(o)
        attrs = JSON.parse(o['data'])
        Solicitud::Language.new(attrs['code'])
      end
    end
  end
end
