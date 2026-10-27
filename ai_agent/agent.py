"""LangGraph graph for the Telegram bot's tool-free IA endpoint."""

import os
from typing import TypedDict

import httpx
from langgraph.graph import END, START, StateGraph


class AgentState(TypedDict):
    prompt: str
    answer: str

# Aca construimos el grafo de estados para el agente
async def answer_with_ollama(state: AgentState) -> dict[str, str]:
    """The only graph node. Tools can be added later as additional nodes."""
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{os.getenv('OLLAMA_BASE_URL', 'http://localhost:11434')}/api/chat",
            json={
                "model": os.getenv('OLLAMA_MODEL', 'llama3.2:latest'),
                "messages": [
                    {
                        "role": "system",
                        "content": "Respondé en español, de forma clara y concisa.",
                    },
                    {"role": "user", "content": state["prompt"]},
                ],
                "stream": False,
            },
        )
        response.raise_for_status()
        answer = response.json()["message"]["content"].strip()
    return {"answer": answer}


workflow = StateGraph(AgentState)
workflow.add_node("answer_with_ollama", answer_with_ollama)
workflow.add_edge(START, "answer_with_ollama")
workflow.add_edge("answer_with_ollama", END)
agent = workflow.compile()
