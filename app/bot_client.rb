require 'telegram/bot'
require "#{File.dirname(__FILE__)}/../app/routes"
require "#{File.dirname(__FILE__)}/application/ia/respond_to_prompt"
require "#{File.dirname(__FILE__)}/infrastructure/ia/langgraph_agent_client"
require 'semantic_logger'

class BotClient
  def initialize(token = ENV['TELEGRAM_TOKEN'], log_level = ENV['LOG_LEVEL'] || 'error', log_url = ENV['LOG_URL'], ai_responder: nil)
    @token = token
    @username = ENV['TELEGRAM_USERNAME']
    SemanticLogger.default_level = log_level.to_sym
    SemanticLogger.add_appender(
      io: $stdout
    )
    unless log_url.nil? || log_url.empty?
      SemanticLogger.add_appender(
        appender: :http,
        url: log_url,
        application: 'bot'
      )
    end
    @logger = SemanticLogger['BotClient']
    @routes = Routes.new(ai_responder: ai_responder || default_ai_responder)
  end

  def start
    @logger.info "Starting bot version:#{Version.current}"
    @logger.info "username is #{@username}"
    run_client do |bot|
      bot.listen { |message| handle_message(message, bot) }
    rescue StandardError => e
      @logger.fatal e.message
    end
  end

  def run_once
    run_client do |bot|
      bot.fetch_updates { |message| handle_message(message, bot) }
    end
  end

  private

  def run_client(&block)
    Telegram::Bot::Client.run(@token, logger: @logger) { |bot| block.call bot }
  end

  def handle_message(message, bot)
    @logger.debug "From: @#{message.from.username}, message: #{message.inspect}"

    @routes.handle(bot, message)
  end

  # ESTE METODO ES LA CLAVE, YA QUE DEFINE LA IA POR DEFECTO QUE TENDRA INTEGRADO EL BOT
  def default_ai_responder
    client = Ia::Infrastructure::LanggraphAgentClient.new(
      base_url: ENV.fetch('LANGGRAPH_AGENT_URL', 'http://localhost:8000')
    )
    Ia::Application::RespondToPrompt.new(answer_question: client)
  end
end
