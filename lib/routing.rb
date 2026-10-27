module Routing
  @message_handlers = {}
  @regex_message_handlers = {}
  @callback_query_handlers = {}
  @callback_location_handler = nil

  DEFAULT = '_default_handler_'.freeze

  def self.message_handlers
    @message_handlers
  end

  def self.regex_message_handlers
    @regex_message_handlers
  end

  def self.callback_query_handlers
    @callback_query_handlers
  end

  def self.callback_location_handler
    @callback_location_handler
  end

  def self.callback_location_handler=(handler)
    @callback_location_handler = handler
  end

  def self.included(clazz)
    clazz.extend ClazzMethods
  end

  def handle(bot, message)
    handler = find_handler_for(message)
    handler, named_captures = find_regex_handler_for(message) if handler.nil?

    if !handler.nil?
      instance_exec(bot, message, named_captures, &handler)
    else
      instance_exec(bot, message, &(handler || default_handler(message)))
    end
  end

  module ClazzMethods
    def on_message(expected_message, &block)
      Routing.message_handlers[expected_message] = block
    end

    def on_message_pattern(expected_message_regex, &block)
      Routing.regex_message_handlers[expected_message_regex] = block
    end

    def on_response_to(expected_message, &block)
      Routing.callback_query_handlers[expected_message] = block
    end

    def on_location_response(&block)
      Routing.callback_location_handler = block
    end

    def default(&block)
      Routing.message_handlers[DEFAULT] = block
    end
  end

  private

  def find_handler_for(message)
    case message
    when Telegram::Bot::Types::Message
      if message.location.nil?
        Routing.message_handlers[message.text]
      else
        Routing.callback_location_handler
      end
    when Telegram::Bot::Types::CallbackQuery
      Routing.callback_query_handlers[message.message.text]
    end
  end

  def find_regex_handler_for(message)
    message_text = message.text
    regex, handler = Routing.regex_message_handlers.find do |regex, _block|
      message_text =~ regex
    end
    return unless handler

    matches = message_text.match(regex)
    [handler, matches.named_captures]
  end

  def default_handler(message)
    Routing.message_handlers[DEFAULT] ||
      (raise "Unkown message [#{message.inspect}]. Please define new handler or a default handler")
  end
end
