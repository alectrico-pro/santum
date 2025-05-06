module Graph
  module Solicitud
    class Component < Base

      attr_accessor :type
      attr_accessor :sub_type
      attr_accessor :index
      attr_accessor :parameters

      def initialize(type='', sub_type='', index='', parameters=[])

        @type       = type
        @sub_type   = sub_type
        @index      = index
        @parameters = parameters

      end

      def to_json(*a)

          data= {
                  'type' => @type,
              'sub_type' => @sub_type,
                 'index' => @index,
            'parameters' => @parameters }

        {  'json_class'  => self.class.name,
                 'data'  => data.to_json(*a)  }

      end

      def self.json_create(o)

        attrs = JSON.parse(o['data'], :quirks_mode => true )

        parameters = attrs['parameters']
        parameters_list = []
        unless parameters.nil?
          parameters.each do |parameter_data|
            parameter_json = {'json_class' => 'Graph::Solicitud::Parameter',
                              'data'       => parameter_data.to_json}
            parameter = ::Graph::Solicitud::Parameter.json_create( parameter_json )
            parameters_list << parameter
          end
        end

        ::Graph::Solicitud::Component.new(
          attrs['type'], 
          attrs['sub_type'], 
          attrs['index'],
          parameters_list )

      end

    end
  end
end
