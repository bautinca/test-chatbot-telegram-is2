module Tv
  # Todas las series de TV que tenemos en la 'base de datos' (en realidad no tenemos una base de datos,
  # pero para este ejemplo vamos a simular que tenemos una base de datos con un array de objetos Tv::Series)
  class Series
    attr_reader :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end

    # De aca obtenemos todas las series de TV donde lo usamos en el endpoint /tv del bot
    def self.all
      [Tv::Series.new(1, 'Jon Snow'),
       Tv::Series.new(2, 'Daenerys Targaryen'),
       Tv::Series.new(3, 'Ned Stark')]
    end

    # Recibe el ID de la serie que el usuario selecciono y devuelve un mensaje hardcodeado segun la serie
    def self.handle_response(series_id)
      responses = ['Jon es demasiado bueno, nunca lo va a aceptar!',
                   'A mi también me encantan los dragones!',
                   'Ned se murió!']
      responses[series_id.to_i - 1] # Segun el ID de la serie que el usuario selecciono le restamos 1 para obtener el indice del array de respuestas y devolvemos la respuesta correspondiente
    end
  end
end
