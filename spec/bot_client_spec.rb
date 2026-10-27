require 'spec_helper'
require 'web_mock'
# Uncomment to use VCR
# require 'vcr_helper'

require "#{File.dirname(__FILE__)}/../app/bot_client"

# -------------FUNCIONES HELPERS----------------
# Esta funcion helper simula que el bot recibe un mensaje con el comando /version
def when_i_send_text(token, message_text)
  # Si nos fijamos todo el body esta hardcodeado salvo el message_text que es el texto del mensaje que el bot recibe
  body = { "ok": true, "result": [{ "update_id": 693_981_718,
                                    "message": { "message_id": 11,
                                                 "from": { "id": 141_733_544, "is_bot": false, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "language_code": 'en' },
                                                 "chat": { "id": 141_733_544, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                                                 "date": 1_557_782_998, "text": message_text, # Aca lo recibe por parametro
                                                 "entities": [{ "offset": 0, "length": 6, "type": 'bot_command' }] } }] }

  # Cuando mi app envia una request a esta URL en realidad no la envia, nunca sale de la red sino que se queda en la maquina
  # El stub request es importante ya que permite que el mensaje nunca llegue a la API de Telegram sino que intercepta el paquete y lo devuelve con el body que le pasamos por parametro.
  stub_request(:any, "https://api.telegram.org/bot#{token}/getUpdates")
    .to_return(body: body.to_json, status: 200, headers: { 'Content-Length' => 3 }) # El to_return es lo que devuelve la request, en este caso devuelve el body que es el mensaje
  # que el bot recibe, el status 200 que significa que la request fue exitosa y los headers que son los encabezados de la request
end

def when_i_send_keyboard_updates(token, message_text, inline_selection)
  body = {
    "ok": true, "result": [{
      "update_id": 866_033_907,
      "callback_query": { "id": '608740940475689651', "from": { "id": 141_733_544, "is_bot": false, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "language_code": 'en' },
                          "message": {
                            "message_id": 626,
                            "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                            "chat": { "id": 141_733_544, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                            "date": 1_595_282_006,
                            "text": message_text,
                            "reply_markup": {
                              "inline_keyboard": [
                                [{ "text": 'Jon Snow', "callback_data": '1' }],
                                [{ "text": 'Daenerys Targaryen', "callback_data": '2' }],
                                [{ "text": 'Ned Stark', "callback_data": '3' }]
                              ]
                            }
                          },
                          "chat_instance": '2671782303129352872',
                          "data": inline_selection }
    }]
  }

  stub_request(:any, "https://api.telegram.org/bot#{token}/getUpdates")
    .to_return(body: body.to_json, status: 200, headers: { 'Content-Length' => 3 })
end

def then_i_get_text(token, message_text)
  body = { "ok": true,
           "result": { "message_id": 12,
                       "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                       "chat": { "id": 141_733_544, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                       "date": 1_557_782_999, "text": message_text } }

  stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
    .with(
      body: { 'chat_id' => '141733544', 'text' => message_text }
    )
    .to_return(status: 200, body: body.to_json, headers: {})
end

def then_i_get_keyboard_message(token, message_text)
  body = { "ok": true,
           "result": { "message_id": 12,
                       "from": { "id": 715_612_264, "is_bot": true, "first_name": 'fiuba-memo2-prueba', "username": 'fiuba_memo2_bot' },
                       "chat": { "id": 141_733_544, "first_name": 'Emilio', "last_name": 'Gutter', "username": 'egutter', "type": 'private' },
                       "date": 1_557_782_999, "text": message_text } }

  stub_request(:post, "https://api.telegram.org/bot#{token}/sendMessage")
    .with(
      body: { 'chat_id' => '141733544',
              'reply_markup' => '{"inline_keyboard":[[{"text":"Jon Snow","callback_data":"1"},{"text":"Daenerys Targaryen","callback_data":"2"},{"text":"Ned Stark","callback_data":"3"}]]}',
              'text' => 'Quien se queda con el trono?' }
    )
    .to_return(status: 200, body: body.to_json, headers: {})
end

def stub_pokemon_response(pokemon_name)
  response_body = {
    "name": pokemon_name,
    "height": 5,
    "weight": 90
  }.to_json

  stub_request(:get, "https://pokeapi.co/api/v2/pokemon/#{pokemon_name}")
    .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
end

# -------------------------------------------------

describe 'BotClient' do
  # Primer test cuando envio el comando /version y el bot me responde con la version actual
  it 'should get a /version message and respond with current version' do
    token = 'fake_token'

    when_i_send_text(token, '/version') # Usamos la funcion helper when_i_send_text para simular que el bot recibe un mensaje con el comando /version
    then_i_get_text(token, Version.current) # Usamos la funcion helper then_i_get_text para simular que el bot responde con la version actual del bot

    app = BotClient.new(token) # Creamos una instancia de la clase BotClient con el token del bot

    app.run_once
  end

  it 'should get a /say_hi message and respond with Hola Emilio' do
    token = 'fake_token'

    when_i_send_text(token, '/say_hi Emilio')
    then_i_get_text(token, 'Hola, Emilio')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /start message and respond with Hola' do
    token = 'fake_token'

    when_i_send_text(token, '/start')
    then_i_get_text(token, 'Hola, Emilio')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /stop message and respond with Chau' do
    token = 'fake_token'

    when_i_send_text(token, '/stop')
    then_i_get_text(token, 'Chau, egutter')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a /tv message and respond with an inline keyboard' do
    token = 'fake_token'

    # Enviamos el comando /tv y esperamos que el bot nos responda con un mensaje que tenga un teclado inline con los nombres de las series de TV que tenemos en la base de datos
    when_i_send_text(token, '/tv')
    then_i_get_keyboard_message(token, 'Quien se queda con el trono?') # Usamos la funcion helper then_i_get_keyboard_message para simular que el bot responde con un mensaje que tiene un teclado inline con los nombres de las series de TV que tenemos en la base de datos

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get a "Quien se queda con el trono?" message and respond with' do
    token = 'fake_token'

    when_i_send_keyboard_updates(token, 'Quien se queda con el trono?', '2')
    then_i_get_text(token, 'A mi también me encantan los dragones!')

    app = BotClient.new(token)

    app.run_once
  end

  it 'should get an unknown message message and respond with Do not understand' do
    token = 'fake_token'

    when_i_send_text(token, '/unknown')
    then_i_get_text(token, 'Uh? No te entiendo! Me repetis la pregunta?')

    app = BotClient.new(token)

    app.run_once
  end

  # Hacemos test nuevo que use la API publica de Pokemon
  it 'should get a /pokemon message and respond with the pokemon name' do
    token = 'fake_token'

    stub_pokemon_response('squirtle') # Stub de la respuesta de la API publica de Pokemon para el pokemon Ditto
    when_i_send_text(token, '/pokemon squirtle')
    then_i_get_text(token, 'Pokemon: squirtle - Height: 5 - Weight: 90')

    BotClient.new(token).run_once
  end

  it 'delegates /ia prompts to the IA use case' do
    token = 'fake_token'
    responder = instance_double(Ia::Application::RespondToPrompt)

    when_i_send_text(token, '/ia hola como estas?')
    then_i_get_text(token, '¡Estoy muy bien!')
    allow(responder).to receive(:call).with(prompt: 'hola como estas?').and_return('¡Estoy muy bien!')

    BotClient.new(token, ai_responder: responder).run_once
  end
end
