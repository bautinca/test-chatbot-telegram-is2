require "#{File.dirname(__FILE__)}/../lib/routing"
require "#{File.dirname(__FILE__)}/../lib/version"
require "#{File.dirname(__FILE__)}/tv/series"

# Esta clase representa los distintos endpoints de la API de Telegram que el bot puede recibir
# Cada endpoint tiene un bloque de código que se ejecuta cuando el bot recibe un mensaje que coincide con el endpoint.
class Routes
  include Routing

  def initialize(ai_responder:)
    @ai_responder = ai_responder
  end

  on_message '/start' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{message.from.first_name}")
  end

  on_message_pattern %r{/say_hi (?<name>.*)} do |bot, message, args|
    bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{args['name']}")
  end

  # Este endpoint responde con un mensaje de despedida cuando el bot recibe el comando /stop
  on_message '/stop' do |bot, message|
    # Si nos fijamos del mensaje podemos obtener el username de la persona que nos envio el mensaje, y lo usamos para despedirnos de esa persona
    bot.api.send_message(chat_id: message.chat.id, text: "Chau, #{message.from.username}")
  end

  # Este endpoint responde con la hora actual del servidor cuando el bot recibe el comando /time
  on_message '/time' do |bot, message|
    # bot.api.send_message() sirve para que el bot envie un mensaje al chat, luego recibe tambien el ID del chat y el
    # text que es el mensaje que queremos enviar donde obtenemos el Time.now que devuelve la hora actual del servidor
    bot.api.send_message(chat_id: message.chat.id, text: "La hora es, #{Time.now}")
  end

  # Este endpoint esta bueno ya que cuando el bot recibe el comando /tv, responde con un mensaje que tiene un teclado inline con los nombres de las series de TV que tenemos en la base de datos
  # y cuando el usuario hace click en una de las series, el bot responde con un mensaje que dice "La serie X es la mejor" donde X es el nombre de la serie que el usuario selecciono.
  on_message '/tv' do |bot, message|
    # El teclado inline es un teclado que aparece debajo del mensaje y permite al usuario interactuar con el bot sin tener que escribir un mensaje.
    # Lo que hacemos es crear un array de botones inline donde cada boton tiene el nombre de la serie y el id de la serie como callback_data,
    # luego creamos un objeto InlineKeyboardMarkup con el array de botones y lo enviamos al usuario.
    # Si nos fijamos el array de botones se crea a partir de la clase Tv::Series en el archivo tv/series.rb que tiene un metodo all que devuelve todas las series de TV que
    # tenemos en la base de datos y luego usamos el metodo map para crear un array de botones inline donde cada boton tiene el nombre de la serie y el id de la serie como callback_data.
    kb = [Tv::Series.all.map do |tv_serie|
      Telegram::Bot::Types::InlineKeyboardButton.new(text: tv_serie.name, callback_data: tv_serie.id.to_s)
    end]
    # Le pasamos el array de botones al objeto InlineKeyboardMarkup y lo enviamos al usuario junto con el mensaje "Quien se queda con el trono?"
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    # El reply_markup es un objeto que se envia al usuario junto con el mensaje y permite al usuario interactuar con el bot sin tener que escribir un mensaje.
    bot.api.send_message(chat_id: message.chat.id, text: 'Quien se queda con el trono?', reply_markup: markup)
  end

  on_message '/busqueda_centro' do |bot, message|
    kb = [[
      Telegram::Bot::Types::KeyboardButton.new(text: 'Compartime tu ubicacion', request_location: true)
    ]]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    bot.api.send_message(chat_id: message.chat.id, text: 'Busqueda por ubicacion', reply_markup: markup)
  end

  on_location_response do |bot, message|
    response = "Ubicacion es Lat:#{message.location.latitude} - Long:#{message.location.longitude}"
    puts response
    bot.api.send_message(chat_id: message.chat.id, text: response)
  end

  # ¿Como sabe el bot que responderme en el endpoint /tv cuando hago click en un boton del teclado inline en una de las series?
  # Bueno aca se resuelve esa logica. Cuando el usuario hace click en un boton del teclado inline, el bot recibe un mensaje con el callback_data que es el id de la serie que el usuario selecciono.
  # El texto 'Quien se queda con el trono?' es el texto que le pusimos al mensaje que enviamos al usuario en el endpoint /tv,
  # y cuando el bot recibe un mensaje con ese texto, ejecuta el bloque de codigo que esta aca abajo.
  on_response_to 'Quien se queda con el trono?' do |bot, message|
    response = Tv::Series.handle_response message.data # El message.data es el callback_data que es el id de la serie que seteamos en el boton inline
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
  end

  # Por ejemplo al mandarle el comando /version el bot responde con la version actual del bot
  on_message '/version' do |bot, message|
    # bot.api.send_message() sirve para que el bot envie un mensaje al chat
    # Por otro lado para saber a quien le mandamos el mensaje tenemos que poner el ID del chat
    bot.api.send_message(chat_id: message.chat.id, text: Version.current) # La clase Version tiene un metodo current que devuelve la version actual del bot, la clase esta en ./lib/version.rb
  end

  # ------------ MENSAJES NUEVO -----------------
  # Vamos a usar la libreria Faraday que sirve para hacer peticiones HTTP a otras APIs, en este caso usaremos la API publica
  # de Pokemon para obtener info. de los pokemones (en este caso del pokemon Ditto)
  on_message '/pokemon' do |bot, message|
    # Con Faraday hacemos un HTTP GET al endpoint https://pokeapi.co/api/v2/pokemon/ditto para obtener info del pokemon Ditto
    response = Faraday.get('https://pokeapi.co/api/v2/pokemon/ditto')
    response_json = JSON.parse(response.body) # Parseamos la respuesta a JSON
    pokemon_text = "Pokemon: #{response_json['name']}"
    bot.api.send_message(chat_id: message.chat.id, text: pokemon_text)
  end

  # En este otro mensaje vamos a poder pasar como parametro el nombre del pokemon que queremos buscar y el bot nos devolvera la info de ese pokemon
  # Usamos un regex para capturar el nombre del pokemon que el usuario quiere buscar
  on_message_pattern %r{/pokemon (?<name>.*)} do |bot, message, args| # El 'args' es un hash que contiene los parametros que capturamos
    #                                                                 # con el regex, en este caso el nombre del pokemon que el usuario quiere buscar
    response = Faraday.get("https://pokeapi.co/api/v2/pokemon/#{args['name']}") # Lo pasamos como parametro a la URL de la API de Pokemon para obtener info del pokemon que el usuario quiere buscar
    response_json = JSON.parse(response.body)
    pokemon_text = "Pokemon: #{response_json['name']} - Height: #{response_json['height']} - Weight: #{response_json['weight']}" # Hacemos que nos devuelva el nombre del pokemon, su altura y peso
    bot.api.send_message(chat_id: message.chat.id, text: pokemon_text)
  end

  # Nuevo endpoint donde le pasamos /render <nombre_pokemon> y nos devuelve una imagen del pokemon que le pasamos como parametro
  on_message_pattern %r{/render (?<name>.*)} do |bot, message, args|
    response = Faraday.get("https://pokeapi.co/api/v2/pokemon/#{args['name']}") # Lo pasamos como parametro a la URL de la API de Pokemon para obtener info del pokemon que el usuario quiere buscar
    response_json = JSON.parse(response.body)
    pokemon_image_url = response_json['sprites']['front_default'] # Obtenemos la URL de la imagen del pokemon que el usuario quiere buscar
    bot.api.send_photo(chat_id: message.chat.id, photo: pokemon_image_url) # Enviamos la imagen del pokemon al usuario
  end

  on_message_pattern %r{\A/ia(?:\s+(?<prompt>.+))?\z} do |bot, message, args|
    answer = ai_responder.call(prompt: args['prompt'])
    bot.api.send_message(chat_id: message.chat.id, text: answer)
  rescue Ia::Application::EmptyPrompt
    bot.api.send_message(chat_id: message.chat.id, text: 'Escribí una consulta después de /ia. Ejemplo: /ia ¿Cómo estás?')
  rescue Ia::Infrastructure::AgentUnavailable
    bot.api.send_message(chat_id: message.chat.id, text: 'El agente de IA no está disponible en este momento. Intentá de nuevo más tarde.')
  end


  default do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: 'Uh? No te entiendo! Me repetis la pregunta?')
  end

  private

  attr_reader :ai_responder
end
