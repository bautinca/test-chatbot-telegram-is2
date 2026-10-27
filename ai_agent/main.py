from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from agent import agent

app = FastAPI(title="Telegram IA agent")


class AnswerRequest(BaseModel):
    prompt: str


class AnswerResponse(BaseModel):
    answer: str


@app.post("/answer", response_model=AnswerResponse)
async def answer(request: AnswerRequest) -> AnswerResponse:
    try:
        state = await agent.ainvoke({"prompt": request.prompt, "answer": ""})
        return AnswerResponse(answer=state["answer"])
    except Exception as error:
        raise HTTPException(status_code=503, detail="The LLM is unavailable") from error
