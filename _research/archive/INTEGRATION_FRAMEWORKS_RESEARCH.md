# Integration Frameworks Research - February 2026
**Focus**: Orchestration and integration frameworks for voice assistant stacks
**Phase**: Future (Phase 3)

---

## Executive Summary

**Recommendation for Phase 3**: **Pipecat** for modern voice assistants, **LangChain** for complex multi-agent workflows

**Rationale**:
- Pipecat: Purpose-built for real-time voice, massive service ecosystem, low-code pipeline configuration
- LangChain: Largest ecosystem, extensive integrations, best for complex workflows

---

## Framework Comparison Matrix

| Framework | Stars | Purpose | Voice-First | Streaming | STT Services | LLM Services | TTS Services | Pros | Cons |
|-----------|--------|---------|--------------|-----------|---------------|---------------|---------------|-------|-------|
| **Pipecat** | 10.3k | Real-time voice | ✅ | ✅ | 20+ | 20+ | 20+ | Modern, low-code | Python only |
| **LangChain** | 126k | General orchestration | ❌ | ✅ | 400+ | All | Some | Largest ecosystem | Complex, overkill |
| **LlamaIndex** | 46.9k | Data/RAG focus | ❌ | ✅ | 300+ | All | Some | Best for RAG | Data-centric |
| **Haystack** | 24.2k | End-to-end LLM | ❌ | ✅ | Advanced retrieval | All | Some | Production-ready | Smaller community |

---

## Pipecat

### Repository
https://github.com/pipecat-ai/pipecat

### Status
Latest v0.0.101 (Jan 31, 2026), 10.3k stars, very active

### Key Features

**Purpose-Built Design**:
- Real-time voice and multimodal conversational AI
- Voice-first design with streaming capabilities
- 20+ STT services supported
- 20+ LLM services supported
- 20+ TTS services supported

**Services Supported**:

**STT (20+ services)**:
- OpenAI Whisper
- Groq (fast)
- Deepgram (real-time)
- AssemblyAI
- Google Cloud STT
- Azure Speech
- Local: OpenAI Whisper (local), Faster-Whisper, Whisper.cpp
- And more...

**LLM (20+ services)**:
- OpenAI GPT-4
- Anthropic Claude
- Mistral
- Groq
- Local: Ollama, llama.cpp, vLLM
- And more...

**TTS (20+ services)**:
- ElevenLabs (high quality)
- Deepgram (fast)
- Azure
- Google
- Local: Piper, Coqui TTS, Bark
- And more...

**Transports**:
- WebRTC (lowest latency)
- WebSocket
- FastAPI

**Audio Processing**:
- Silero VAD (built-in)
- Noise suppression: Krisp, Koala, AI-coustics filters

**Memory**:
- mem0 integration
- Conversation history management

**Client SDKs**:
- JavaScript
- React
- React Native
- Swift
- Kotlin
- C++
- ESP32 (embedded)

**Architecture**:
- Pipelines and processors
- Modular, composable
- Low-code configuration



### Pros

✅ Modern, purpose-built for voice
✅ Excellent real-time performance
✅ Massive service ecosystem (20+ each category)
✅ Low-code pipeline configuration
✅ Good documentation with examples
✅ Multi-modal capabilities
✅ Active development with frequent releases
✅ WebRTC for lowest latency
✅ Built-in VAD and noise suppression
✅ Memory integration (mem0)
✅ Client SDKs for all platforms

### Cons

❌ Python only (no client SDKs like JS/React)
❌ Steeper learning curve than simpler options
❌ More boilerplate for simple use cases

---

## LangChain

### Repository
https://github.com/langchain-ai/langchain

### Status
Latest langchain-core==1.2.10 (Feb 10, 2026), 126k stars, very active

### Key Features

**Agent Framework**:
- LangGraph for complex workflows
- Multi-agent orchestration with human-in-the-loop

**Integrations (400+)**:
- Model providers: OpenAI, Anthropic, Mistral, Groq, local (Ollama, llama.cpp, vLLM)
- Vector stores: Chroma, Qdrant, LanceDB, Pinecone, Weaviate
- Tools: 100+ (web search, file operations, APIs)

**RAG Capabilities**:
- Vector store integration
- Document ingestion
- Retrieval methods
- Conversation memory

**Features**:
- Streaming responses and async operations
- Enterprise-ready with LangSmith for observability
- Prompt templates
- Chains (sequential workflows)
- Agents (tool-using, multi-agent)
- Memory management (conversation, summary, vector store)


### Streaming with STT/TTS Integration

```python
from langchain_openai import ChatOpenAI
from faster_whisper import WhisperModel
import asyncio

async def voice_assistant():
    # STT
    stt_model = WhisperModel("turbo", device="cuda")
    
    # LLM with streaming
    llm = ChatOpenAI(model="gpt-4", streaming=True)
    
    # Conversation loop
    while True:
        # Capture audio (await user speech)
        # audio_chunk = capture_audio()
        
        # Transcribe
        # segments, _ = stt_model.transcribe(audio_chunk)
        # user_text = " ".join(s.text for s in segments)
        user_text = await get_user_speech()
        
        # Generate response (streaming)
        async for chunk in llm.astream(user_text):
            print(chunk, end="", flush=True)
        
        # TTS (if implemented)
        # await speak_text(response)

asyncio.run(voice_assistant())
```

### Pros

✅ Largest ecosystem and community (400+ integrations)
✅ Extensive documentation and examples
✅ Best for complex multi-agent systems
✅ Rich integration ecosystem
✅ Production-ready features (LangSmith observability)
✅ Streaming with minimal overhead
✅ Flexible for any workflow
✅ Widely used and tested

### Cons

❌ Can be overkill for simple use cases
❌ Steeper learning curve
❌ Heavy dependency tree
❌ Not voice-first (requires custom STT/TTS integration)

---

## LlamaIndex

### Repository
https://github.com/run-llama/llama_index

### Status
Latest v0.14.13 (Jan 21, 2026), 46.9k stars, very active

### Key Features

**Data Framework**:
- LLMs over your data
- 300+ integrations (LlamaHub ecosystem)

**Vector Indices**:
- Advanced retrieval methods
- Query engines
- Retrievers

**RAG Pipelines**:
- Document ingestion
- Query optimization
- Hybrid search (vector + keyword)

**Multi-Modal**:
- Vision + text support
- Multi-document queries


### Pros

✅ Best for RAG/document Q&A applications
✅ Excellent documentation and tutorials
✅ Smaller, focused API
✅ Good local LLM integration via Ollama, LMStudio, llama.cpp
✅ Advanced retrieval methods
✅ Multi-modal support

### Cons

❌ More data-centric vs agent-focused
❌ Less comprehensive agent orchestration
❌ Not voice-first (requires STT/TTS integration)

---

## Haystack

### Repository
https://github.com/deepset-ai/haystack

### Status
Latest v2.23.0 (Jan 27, 2026), 24.2k stars, active

### Key Features

**End-to-End LLM Framework**:
- Pipelines or agents architecture

**Advanced Retrieval**:
- Multiple retrieval methods
- Reranking
- Hybrid search

**Built-in Evaluation**:
- Testing and benchmarking

**Technology Agnostic**:
- Swap components easily
- Multiple LLM providers
- Multiple vector stores

**Features**:
- Multi-modal support
- Pipelines (sequential, parallel, branching)
- Agents (tool-using)
- Memory management

### Pros

✅ Best for RAG, question answering, semantic search
✅ Strong production-ready focus
✅ Flexible and explicit architecture
✅ Good docs with examples
✅ Built-in evaluation and testing

### Cons

❌ Smaller community than LangChain/LlamaIndex
❌ More complex to learn
❌ Not voice-first

---

## Microsoft Semantic Kernel

### Repository
https://github.com/microsoft/semantic-kernel

### Status
Latest python-1.39.4 (Feb 10, 2026), 27.2k stars, very active

### Key Features

**Enterprise-Ready Orchestration**:
- Model flexibility (OpenAI, Azure, Hugging Face, local models)
- Multi-agent systems with specialist agents

**Plugin Ecosystem**:
- Native code
- Prompt templates
- OpenAPI
- MCP (Model Context Protocol)

**Vector DB Support**:
- Azure AI Search
- Chroma
- Qdrant

**Local Deployment**:
- Ollama
- LMStudio
- ONNX

**Process Framework**:
- Complex workflows
- State management
- Error handling

### Pros

✅ Enterprise-grade reliability
✅ Excellent .NET and Java support alongside Python
✅ Strong multi-agent capabilities
✅ Built-in observability and security
✅ Model-agnostic design
✅ Good for complex business applications

### Cons

❌ Microsoft-centric design decisions
❌ More complex than needed for simple use cases
❌ Heavier resource requirements

---

## Recommendations

### For Voice Assistant (Real-Time)

**Best Stack**: Pipecat

**Why**:
- Purpose-built for real-time voice
- Excellent performance with WebRTC
- Massive service ecosystem (20+ each)
- Low-code pipeline configuration
- Built-in VAD and noise suppression
- Memory integration (mem0)

**Configuration**:
```python
from pipecat import Pipeline, processor

pipeline = Pipeline(
    processor.user_audio_frame_processor(),
    processor.STTProcessor(service="ollama", model="whisper-1"),
    processor.LLMProcessor(service="ollama", model="llama3.1:8b"),
    processor.TTSProcessor(service="piper", voice="en_us-lessac"),
    processor.AudioFrameProcessor()
)

# Run with WebRTC transport
await pipeline.run()
```

### For Complex Workflows (Multi-Agent)

**Best Stack**: LangChain

**Why**:
- Largest ecosystem (400+ integrations)
- LangGraph for complex workflows
- Multi-agent orchestration
- Extensive documentation

**Configuration**:
```python
from langchain.agents import initialize_agent, Tool
from langchain_openai import ChatOpenAI

# Initialize LLM
llm = ChatOpenAI(model="gpt-4")

# Define tools
tools = [
    Tool(name="weather", func=get_weather),
    Tool(name="search", func=search_web),
    # ... more tools
]

# Initialize agent
agent = initialize_agent(
    tools=tools,
    llm=llm,
    agent="chat-conversational-react-description",
    verbose=True
)

# Run
result = agent.run("What's the weather in Paris?")
```

### For RAG/Document Q&A

**Best Stack**: LlamaIndex

**Why**:
- Best for data-focused applications
- Advanced retrieval methods
- 300+ integrations
- Multi-modal support

**Configuration**:
```python
from llama_index.core import VectorStoreIndex, Document
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.vector_stores.chroma import ChromaVectorStore

# Load documents
documents = load_documents_from_directory("./docs")

# Create index
index = VectorStoreIndex.from_documents(
    documents,
    embed_model=OpenAIEmbedding(),
    storage_context=storage_context
)

# Query
query_engine = index.as_query_engine()
response = query_engine.query("Your question here")
```

---

## Performance Comparison

| Framework | Purpose | Complexity | Latency | Pros | Cons |
|-----------|---------|------------|----------|-------|-------|
| Pipecat | Real-time voice | Medium | <200ms | Voice-first, massive services | Python only |
| LangChain | General orchestration | High | Variable | Largest ecosystem | Overkill for simple |
| LlamaIndex | Data/RAG | Medium | Variable | Best for RAG | Data-centric |
| Haystack | End-to-end LLM | Medium | Variable | Production-ready | Smaller community |

---

## Summary

**Phase 3 Recommendation**: **Pipecat** for voice assistant

**Why**:
- Purpose-built for real-time voice
- Excellent performance with WebRTC
- Massive service ecosystem
- Built-in VAD and noise suppression
- Low-code pipeline configuration
- Memory integration

**Alternative**: **LangChain** for complex multi-agent workflows

---

## References

- Pipecat: https://github.com/pipecat-ai/pipecat
- LangChain: https://github.com/langchain-ai/langchain
- LlamaIndex: https://github.com/run-llama/llama_index
- Haystack: https://github.com/deepset-ai/haystack
- Semantic Kernel: https://github.com/microsoft/semantic-kernel
