Telegram Bot Example
====================

1. Registrar un nuevo bot con el BotFather de Telegram

* En Telegram https://web.telegram.org/#/im?p=@BotFather (si la url anterior no funciona probar https://web.telegram.org/a/#93372553)
* Enviarle el comando `/newbot`
* Seguir los pasos y al final el BotFather responde con un token

2. Copiar el archivo `.env.example` a `.env` y reemplazar `<YOUR_TELEGRAM_TOKEN>` con el token del paso anterior

3. Correr los tests con `bundle exec rake`

4. Levantar la app localmente con `ruby app.rb`

# Deploy a Heroku

1. Crear la app en heroku
2. Agregar el remote `heroku git:remote -a <app_name>`
3. Hacer deploy con `git push heroku master`
4. Ir a los settings y agregar una nueva variable de entorno `TELEGRAM_TOKEN` con el valor del token
5. Ir a los Dynos, editar los dynos y confirmar la activación (ver [imagen](https://www.dropbox.com/s/h2hqimu7pbsqrhj/Screenshot%202019-05-15%2021.38.07.png?dl=0))

# Testing

Los tests utilizan WebMock. Para testear el cliente, siempre usar `app.run_once` de lo contrario el bot se queda esperando mensajes y el test no finaliza nunca.

# Llamadas a otras API por HTTP

Se puede utilizar la gema incluida en el repo [Faraday](https://github.com/lostisland/faraday#faraday)

# Endpoint de IA: `/ia`

El comando `/ia <consulta>` delega la respuesta a un agente sin herramientas. El bot Ruby no contiene la lógica del modelo: actúa como controlador y llama al puerto de aplicación `Ia::Application::RespondToPrompt`; su adaptador de infraestructura se comunica por HTTP con el servicio `ai_agent`.

El servicio `ai_agent` está escrito en Python porque LangGraph no ofrece una librería oficial para Ruby. Allí hay un grafo LangGraph de un único nodo (`answer_with_ollama`), que consulta un modelo local mediante Ollama. No requiere una API key y usa `qwen2.5:1.5b` por defecto.

Para ejecutarlo localmente se necesitan Python 3.10+ y [Ollama](https://ollama.com):

```sh
ollama pull qwen2.5:1.5b
ollama serve

cd ai_agent
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8000
```

En otra terminal, iniciar el bot con `LANGGRAPH_AGENT_URL=http://localhost:8000`. Por ejemplo, `/ia hola como estás?` llegará al modelo local y su respuesta se enviará al chat de Telegram.

Variables configurables del servicio de IA:

* `LANGGRAPH_AGENT_URL`: URL del servicio LangGraph; por defecto `http://localhost:8000`.
* `OLLAMA_BASE_URL`: URL de Ollama vista por el servicio; por defecto `http://localhost:11434`.
* `OLLAMA_MODEL`: modelo local; por defecto `qwen2.5:1.5b`.

# Correr con docker en modo produccion

docker-compose -f docker-compose.prod.yml --env-file ./.env up --build


# Logging

La aplicación utiliza la gema SemanticLogger
El log level se especifica en la configuracion con uno de los siguientes valores: trace|debug|info|warn|error|fatal.

# Más información

Para utilizar otras funcionalidades de Telegram como los Keyboards especiales ver la doc en: https://github.com/atipugin/telegram-bot-ruby

# Explicacion funcionamiento gral. bot
Este bot es un proceso que esta todo el dia 'polleando' a Telegram pegandole al endpoint **/getUpdates** entonces es un loop que hace getUpdates se fija si tiene un mensaje nuevo, si no tiene un mensaje nuevo duerme un poquito y vuelve a hacer getUpdates. Cuando recibe un mensaje nuevo lo procesa y es ahi donde usa la clase `Routes` para ver que comando es y que respuesta tiene que dar. Si nos fijamos en cada endpoint llamamos a `send_message` que es la funcion que hace el POST a Telegram

Como hace un polling constante a getUpdates es por eso que en los test unitarios en la funcion `when_i_send_text` hacemos un stub de la request a getUpdates para que nunca salga de la maquina y no haga un request real a Telegram. Esto es importante porque si no hacemos el stub, cada vez que corremos los tests se hace un request real a Telegram y eso es muy lento y ademas nos puede bloquear el bot si hacemos muchos requests.

Por otro lado tambien stubeamos el endpoint **/sendMessage** para que nunca salga de la maquina, por eso en la funcion `then_i_get_text` hacemos un stub de la request a sendMessage para que nunca salga de la maquina y no haga un request real a Telegram.
