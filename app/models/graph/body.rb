#parte body de los requests que envía facebook
#que representan cambios en su modelo api graph
#no es el attributo body de graph text
#body en Graph::Text no es un objeto compuesto
#solo es una de un hash
#así: {body "hola"}
module Graph

  class Body
    attr_accessor :data

    def initialize
    end

    def save!
    end

    def put
      'data'
    end
  end

end
