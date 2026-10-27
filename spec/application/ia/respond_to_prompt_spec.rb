require 'spec_helper'
require "#{File.dirname(__FILE__)}/../../../app/application/ia/respond_to_prompt"

RSpec.describe Ia::Application::RespondToPrompt do
  it 'delegates a normalized prompt to the answer port' do
    answer_port = instance_double('AnswerQuestion')
    allow(answer_port).to receive(:call).with(prompt: 'hola').and_return('¡Hola!')

    result = described_class.new(answer_question: answer_port).call(prompt: ' hola ')

    expect(result).to eq('¡Hola!')
  end

  it 'rejects an empty prompt' do
    responder = described_class.new(answer_question: instance_double('AnswerQuestion'))

    expect { responder.call(prompt: ' ') }.to raise_error(Ia::Application::EmptyPrompt)
  end
end
