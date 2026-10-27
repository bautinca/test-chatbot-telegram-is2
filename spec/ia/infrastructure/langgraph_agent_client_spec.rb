require 'spec_helper'
require 'web_mock'
require "#{File.dirname(__FILE__)}/../../../app/infrastructure/ia/langgraph_agent_client"

RSpec.describe Ia::Infrastructure::LanggraphAgentClient do
  it 'sends the prompt to the LangGraph agent and returns its answer' do
    stub_request(:post, 'http://agent.test/answer')
      .with(body: { prompt: 'hola' }.to_json)
      .to_return(status: 200, body: { answer: '¡Hola!' }.to_json)

    answer = described_class.new(base_url: 'http://agent.test').call(prompt: 'hola')

    expect(answer).to eq('¡Hola!')
  end
end
