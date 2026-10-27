require 'faraday'
require 'json'

module Ia
  module Infrastructure
    class AgentUnavailable < StandardError; end

    # Adaptador de salida: invoca el agente LangGraph que se ejecuta fuera del proceso Ruby.
    class LanggraphAgentClient
      def initialize(base_url:, connection: nil)
        @connection = connection || Faraday.new(url: base_url) do |faraday|
          faraday.options.timeout = 30
          faraday.options.open_timeout = 5
        end
      end

      def call(prompt:)
        response = @connection.post('/answer') do |request|
          request.headers['Content-Type'] = 'application/json'
          request.body = JSON.generate(prompt: prompt)
        end
        raise AgentUnavailable, "Agent returned HTTP #{response.status}" unless response.success?

        JSON.parse(response.body).fetch('answer')
      rescue Faraday::Error, JSON::ParserError, KeyError => e
        raise AgentUnavailable, e.message
      end
    end
  end
end
