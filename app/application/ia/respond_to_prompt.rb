module Ia
  module Application
    class EmptyPrompt < StandardError; end

    # Caso de uso: valida la consulta recibida y delega la generación al puerto.
    class RespondToPrompt
      def initialize(answer_question:)
        @answer_question = answer_question
      end

      def call(prompt:)
        normalized_prompt = prompt.to_s.strip
        raise EmptyPrompt if normalized_prompt.empty?

        @answer_question.call(prompt: normalized_prompt)
      end
    end
  end
end
