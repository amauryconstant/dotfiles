# Voice STT - Future Phases and Implementation Patterns
**Date**: February 10, 2026
**Status**: Planning for Phase 2+ implementation
**Prerequisite**: Complete Phase 1 (Core STT implementation)

---

## Overview

This document contains all implementation details and patterns for future phases beyond Phase 1. Content has been consolidated from research documents to focus on practical implementation guidance.

**Phase 1 (Current)**: See `VOICE_STT_IMPLEMENTATION_PLAN.md`
**Phase 2+ (This Document)**: Future enhancements, two-way conversation, advanced features

---

## Table of Contents

1. [Phase 2: Enhanced STT](#phase-2-enhanced-stt)
2. [Phase 3: Two-Way Conversation](#phase-3-two-way-conversation)
3. [Phase 4: Advanced Features](#phase-4-advanced-features)
4. [Phase 5: Production Optimization](#phase-5-production-optimization)
5. [CLI Implementation Patterns](#cli-implementation-patterns)
6. [Audio Processing Implementation](#audio-processing-implementation)
7. [TTS Integration Patterns](#tts-integration-patterns)
8. [LLM Integration Patterns](#llm-integration-patterns)
9. [Framework Integration Patterns](#framework-integration-patterns)
10. [System Integration](#system-integration)

---

## Phase 2: Enhanced STT

### Objectives

- Add Whisper Turbo as backup STT engine
- Implement streaming text output (real-time transcription display)
- Add session saving to files
- Add word-level timestamps
- Implement speaker diarization
- Optimize for RTX 1650

### Implementation: Whisper Turbo Backup

```python
from openai import whisper

class WhisperTranscriber:
    def __init__(self, model_size="turbo", device="cuda"):
        self.model = whisper.load_model(model_size, device=device)

    def transcribe(self, audio_path: str, language: str = "auto"):
        """Transcribe audio with Whisper"""
        result = self.model.transcribe(
            audio_path,
            language=language if language != "auto" else None,
            word_timestamps=True
        )
        return result

# Usage
whisper = WhisperTranscriber(model_size="turbo")
result = whisper.transcribe("audio.wav")
print(result["text"])
```

### Implementation: Streaming Text Output

```python
from rich.live import Live
from rich.console import Console

console = Console()

def transcribe_streaming():
    """Real-time transcription with live display"""

    with Live(console.print("Initializing..."), refresh_per_second=10) as live:

        # Stream from STT engine
        for chunk in stt_model.stream_audio():
            # Update live display
            live.update(console.print(f"[bold cyan]{chunk.text}", end="", flush=True))

            # Show confidence if available
            if chunk.confidence:
                confidence_style = "green" if chunk.confidence > 0.9 else "yellow"
                live.update(console.print(f"[{confidence_style}] {chunk.confidence:.1%}"))
```

### Implementation: Session Saving

```python
import json
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass, asdict

@dataclass
class TranscriptionSegment:
    text: str
    start_time: float
    end_time: float
    confidence: float
    language: str

@dataclass
class STTSession:
    segments: list[TranscriptionSegment]
    language: str
    total_duration: float
    timestamp: str

class SessionManager:
    def __init__(self, sessions_dir: Path):
        self.sessions_dir = sessions_dir
        self.sessions_dir.mkdir(parents=True, exist_ok=True)

    def save_session(self, session: STTSession):
        """Save transcription session to file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filepath = self.sessions_dir / f"session_{timestamp}.json"

        with open(filepath, "w") as f:
            json.dump(asdict(session), f, indent=2)

        return filepath

    def save_markdown(self, session: STTSession):
        """Save transcription as readable markdown"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filepath = self.sessions_dir / f"session_{timestamp}.md"

        md = f"# Transcription - {session.timestamp}\n\n"
        md += f"Language: {session.language}\n"
        md += f"Duration: {session.total_duration:.1f}s\n\n"
        md += "---\n\n"

        for segment in session.segments:
            start_min, start_sec = divmod(int(segment.start_time), 60)
            md += f"## [{start_min:02d}:{start_sec:02d}]\n\n"
            md += f"{segment.text}\n\n"

        with open(filepath, "w") as f:
            f.write(md)

        return filepath
```

### Implementation: Speaker Diarization

```python
from pyannote.audio import Pipeline

class SpeakerDiarizer:
    def __init__(self, hf_token: str):
        self.pipeline = Pipeline.from_pretrained(
            "pyannote/speaker-diarization-3.1",
            use_auth_token=hf_token
        )

    def diarize(self, audio_path: str) -> dict:
        """Identify speakers in audio"""
        diarization = self.pipeline(audio_path)

        speakers = {}
        for turn, _, speaker in diarization.itertracks(yield_label=True):
            if speaker not in speakers:
                speakers[speaker] = []
            speakers[speaker].append({
                "start": turn.start,
                "end": turn.end,
            })

        return speakers
```

### RTX 1650 Optimization

```python
def detect_and_optimize_for_gpu():
    """Auto-detect GPU and optimize settings"""
    import subprocess

    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
            capture_output=True, text=True, timeout=5
        )

        if "1650" in result.stdout.lower():
            return {
                "model": "small-streaming",
                "precision": "int8",
                "chunk_duration_ms": 800,
                "sample_rate": 16000,
            }
        elif "4090" in result.stdout.lower():
            return {
                "model": "medium-streaming",
                "precision": "float16",
                "chunk_duration_ms": 500,
                "sample_rate": 16000,
            }

    except Exception:
        pass

    return {"model": "tiny-streaming", "precision": "int8"}
```

---

## Phase 3: Two-Way Conversation

### Objectives

- Add TTS engine (Chatterbox for RTX 4090, Kokoro for RTX 1650)
- Add LLM backend (Ollama primary, llama.cpp performance option)
- Implement Pipecat integration for voice orchestration
- Add conversation memory (LanceDB primary, Chroma fallback)
- Implement conversational state machine

### Technology Stack

**Phase 3 Components**:
| Component | RTX 4090 | RTX 1650 |
|-----------|-----------|-----------|
| TTS Engine | Chatterbox | Kokoro 82M |
| LLM Backend | Ollama (Gemma 3 4B) | llama.cpp (Phi-4-mini) |
| Orchestration | Pipecat | Pipecat |
| Memory | LanceDB | LanceDB |
| Transport | WebRTC | WebRTC |

### TTS Engine: Chatterbox (RTX 4090)

```python
from chatterbox.tts import ChatterboxTTS
import soundfile as sf

class ChatterboxSynthesizer:
    def __init__(self, device="cuda"):
        self.model = ChatterboxTTS.from_pretrained(device=device)

    def synthesize(self, text: str) -> tuple[bytes, int]:
        """Synthesize speech from text"""
        wav = self.model.generate(text)
        sample_rate = 24000  # Chatterbox default

        # Return audio bytes and sample rate
        return wav.squeeze().numpy(), sample_rate

    def synthesize_to_file(self, text: str, output_path: str):
        """Synthesize and save to file"""
        wav, sample_rate = self.synthesize(text)
        sf.write(output_path, wav, sample_rate)
```

### TTS Engine: Kokoro 82M (RTX 1650)

```python
from kokoro import KPipeline
import soundfile as sf

class KokoroSynthesizer:
    def __init__(self, voice="af_heart", lang_code='a'):
        self.pipeline = KPipeline(lang_code=lang_code)
        self.voice = voice

    def synthesize(self, text: str) -> tuple[bytes, int]:
        """Synthesize speech from text"""
        generator = self.pipeline(text, voice=self.voice)

        audio_segments = []
        for i, (gs, ps, audio) in enumerate(generator):
            audio_segments.append(audio)

        # Concatenate segments
        import numpy as np
        full_audio = np.concatenate(audio_segments)

        return full_audio, 24000  # Kokoro uses 24kHz

    def synthesize_to_file(self, text: str, output_path: str):
        """Synthesize and save to file"""
        wav, sample_rate = self.synthesize(text)
        sf.write(output_path, wav, sample_rate)
```

### LLM Backend: Ollama

```python
import requests
from openai import OpenAI

class OllamaClient:
    def __init__(self, base_url="http://localhost:11434", model="gemma3:4b"):
        self.client = OpenAI(base_url=base_url, api_key="dummy-key")
        self.model = model

    def generate(self, prompt: str, stream: bool = True) -> str:
        """Generate response from LLM"""
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a helpful voice assistant."},
                {"role": "user", "content": prompt}
            ],
            stream=stream,
            temperature=0.7
        )

        if stream:
            full_response = ""
            for chunk in response:
                if chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    full_response += content
                    yield content
            return full_response
        else:
            return response.choices[0].message.content

    def generate_sync(self, prompt: str) -> str:
        """Synchronous generation (non-streaming)"""
        return "".join(list(self.generate(prompt, stream=False)))
```

### LLM Backend: llama.cpp

```python
import subprocess
import json
from pathlib import Path

class LlamaCppClient:
    def __init__(self, model_path: str, host="localhost", port=8080):
        self.server_url = f"http://{host}:{port}/v1"
        self.model_path = model_path

    def start_server(self):
        """Start llama-server in background"""
        cmd = [
            "llama-server",
            "-m", self.model_path,
            "--port", "8080",
            "--host", "localhost"
        ]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def generate(self, prompt: str, stream: bool = True):
        """Generate response via OpenAI-compatible API"""
        import requests

        response = requests.post(
            f"{self.server_url}/chat/completions",
            json={
                "model": "model",
                "messages": [
                    {"role": "system", "content": "You are a helpful voice assistant."},
                    {"role": "user", "content": prompt}
                ],
                "stream": stream,
                "temperature": 0.7
            }
        )

        if stream:
            for line in response.iter_lines():
                if line:
                    data = json.loads(line.decode())
                    if "choices" in data and data["choices"]:
                        content = data["choices"][0].get("delta", {}).get("content", "")
                        if content:
                            yield content
        else:
            return response.json()["choices"][0]["message"]["content"]
```

### Pipecat Integration

```python
import asyncio
from pipecat import Pipeline, processor, audio

async def run_voice_assistant():
    pipeline = Pipeline()

    # Audio input from microphone
    mic = processor.user_audio_frame_processor()

    # Speech-to-text
    stt = processor.STTProcessor(
        service="ollama",
        model="whisper-1",
        options={"language": "en", "task": "transcribe"}
    )

    # LLM processing
    llm = processor.LLMProcessor(
        service="ollama",
        model="gemma3:4b",
        system_prompt="You are a helpful voice assistant"
    )

    # Text-to-speech
    tts = processor.TTSProcessor(
        service="chatterbox",
        voice="default",
        options={"speed": 1.0}
    )

    # Audio output
    audio_out = processor.AudioFrameProcessor()

    # Connect components
    pipeline.join([mic, stt, llm, tts, audio_out])

    # Run pipeline
    await pipeline.run()

# Usage
asyncio.run(run_voice_assistant())
```

### Conversation Memory: LanceDB

```python
import lancedb
import numpy as np
from datetime import datetime

class ConversationMemory:
    def __init__(self, db_path: str):
        self.connection = lancedb.connect(db_path)

        # Create table for conversation history
        self.conversations = self.connection.create_table(
            "conversations",
            schema=[
                ("role", "str"),
                ("content", "str"),
                ("timestamp", "datetime"),
                ("session_id", "str")
            ],
            mode="overwrite"
        )

    def add_message(self, session_id: str, role: str, content: str):
        """Add message to conversation history"""
        self.conversations.add([{
            "role": role,
            "content": content,
            "timestamp": datetime.now(),
            "session_id": session_id
        }])

    def get_recent_history(self, session_id: str, limit: int = 10) -> list[dict]:
        """Get recent messages from conversation"""
        results = self.conversations.search().where(f"session_id = '{session_id}'").limit(limit).to_list()
        return results

    def get_context(self, session_id: str) -> list[dict]:
        """Get conversation context for LLM"""
        history = self.get_recent_history(session_id, limit=10)

        # Format as OpenAI messages
        context = []
        for msg in history:
            context.append({
                "role": msg["role"],
                "content": msg["content"]
            })

        return context
```

### Conversational State Machine

```python
from enum import Enum
from dataclasses import dataclass

class ConversationState(Enum):
    IDLE = "idle"
    LISTENING = "listening"
    PROCESSING = "processing"
    SPEAKING = "speaking"

@dataclass
class StateTransition:
    current: ConversationState
    trigger: str
    next: ConversationState

class ConversationStateMachine:
    def __init__(self):
        self.state = ConversationState.IDLE
        self.transitions = {
            ConversationState.IDLE: [
                StateTransition(ConversationState.IDLE, "hotkey", ConversationState.LISTENING),
            ],
            ConversationState.LISTENING: [
                StateTransition(ConversationState.LISTENING, "speech_detected", ConversationState.PROCESSING),
                StateTransition(ConversationState.LISTENING, "timeout", ConversationState.IDLE),
            ],
            ConversationState.PROCESSING: [
                StateTransition(ConversationState.PROCESSING, "stt_complete", ConversationState.SPEAKING),
                StateTransition(ConversationState.PROCESSING, "error", ConversationState.IDLE),
            ],
            ConversationState.SPEAKING: [
                StateTransition(ConversationState.SPEAKING, "tts_complete", ConversationState.IDLE),
            ]
        }

    def transition(self, trigger: str) -> ConversationState:
        """Attempt state transition"""
        current_transitions = self.transitions.get(self.state, [])

        for transition in current_transitions:
            if transition.trigger == trigger:
                self.state = transition.next
                return self.state

        return self.state

    def get_state(self) -> ConversationState:
        """Get current state"""
        return self.state
```

---

## Phase 4: Advanced Features

### Objectives

- Add real-time streaming UI (Textual TUI)
- Implement RAG/document Q&A (LlamaIndex)
- Add visual assistant (Llama 4 Vision)
- Implement multi-agent workflows (LangChain)
- Add custom voice cloning

### Real-Time Streaming UI with Textual

```python
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Static, ProgressBar
from textual.containers import Container

class VoiceAssistantApp(App):
    CSS = """
    Screen {
        layout: vertical;
    }
    #main {
        height: 1fr;
    }
    #transcription {
        height: 3fr;
        overflow-y: auto;
    }
    """

    def compose(self) -> ComposeResult:
        yield Header()
        yield Container(
            Static("Status: Ready", id="status"),
            Static("", id="transcription"),
            id="main"
        )
        yield Footer()

    def on_stt_start(self):
        self.query_one("#status").update("Status: Listening...")

    def on_stt_text(self, text: str):
        current = self.query_one("#transcription").renderable
        self.query_one("#transcription").update(f"{current}\n{text}")

    def on_tts_speaking(self):
        self.query_one("#status").update("Status: Speaking...")

# Usage
app = VoiceAssistantApp()
app.run()
```

### RAG with LlamaIndex

```python
from llama_index.core import VectorStoreIndex, Document
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI
from llama_index.vector_stores.chroma import ChromaVectorStore
import chromadb

class RAGAssistant:
    def __init__(self, docs_path: str):
        # Load documents
        documents = self._load_documents(docs_path)

        # Create index
        self.index = VectorStoreIndex.from_documents(
            documents,
            embed_model=OpenAIEmbedding(),
            storage_context=self._get_storage_context()
        )

    def _load_documents(self, path: str) -> list[Document]:
        """Load documents for RAG"""
        # Implement document loading logic
        # Can be PDF, text files, markdown, etc.
        return []

    def _get_storage_context(self):
        """Setup Chroma vector store"""
        chroma_client = chromadb.PersistentClient(path="./db")
        vector_store = ChromaVectorStore(chroma_client=chroma_client)
        return StorageContext.from_defaults(vector_store=vector_store)

    def query(self, question: str) -> str:
        """Query RAG system"""
        query_engine = self.index.as_query_engine()
        response = query_engine.query(question)
        return str(response)
```

### Visual Assistant with Llama 4 Vision

```python
import base64
from openai import OpenAI

class VisionAssistant:
    def __init__(self, base_url="http://localhost:11434"):
        self.client = OpenAI(base_url=base_url, api_key="dummy-key")

    def encode_image(self, image_path: str) -> str:
        """Encode image to base64"""
        with open(image_path, "rb") as f:
            return base64.b64encode(f.read()).decode()

    def analyze_image(self, image_path: str, prompt: str) -> str:
        """Analyze image with vision model"""
        base64_image = self.encode_image(image_path)

        response = self.client.chat.completions.create(
            model="llama4-vision",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ]
        )

        return response.choices[0].message.content
```

### Multi-Agent Workflows with LangChain

```python
from langchain.agents import initialize_agent, Tool
from langchain_openai import ChatOpenAI

class MultiAgentAssistant:
    def __init__(self):
        self.llm = ChatOpenAI(model="gpt-4", streaming=True)

        # Define tools for agents
        self.tools = [
            Tool(
                name="weather",
                func=self._get_weather,
                description="Get current weather for a location"
            ),
            Tool(
                name="search",
                func=self._web_search,
                description="Search the web for information"
            ),
            Tool(
                name="calculator",
                func=self._calculate,
                description="Perform mathematical calculations"
            ),
            Tool(
                name="voice_assistant",
                func=self._stt_tts,
                description="Speech-to-text and text-to-speech operations"
            ),
        ]

        # Initialize multi-agent system
        self.agent = initialize_agent(
            tools=self.tools,
            llm=self.llm,
            agent="chat-conversational-react-description",
            verbose=True
        )

    def _get_weather(self, location: str) -> str:
        """Get weather for location"""
        # Implement weather API integration
        return f"Weather in {location}: Sunny, 72°F"

    def _web_search(self, query: str) -> str:
        """Search web"""
        # Implement web search
        return f"Search results for: {query}"

    def _calculate(self, expression: str) -> str:
        """Perform calculation"""
        try:
            result = eval(expression)
            return str(result)
        except Exception as e:
            return f"Error: {e}"

    def _stt_tts(self, action: str) -> str:
        """STT/TTS operations"""
        # Implement voice operations
        return f"Voice operation: {action}"

    def process_request(self, user_input: str) -> str:
        """Process user request through multi-agent system"""
        response = self.agent.run(user_input)
        return str(response)
```

---

## Phase 5: Production Optimization

### Objectives

- Add performance monitoring and logging
- Implement error recovery and graceful degradation
- Add automated testing suite
- Create deployment automation
- Optimize for multi-user scenarios

### Performance Monitoring

```python
import time
from dataclasses import dataclass
from typing import Optional

@dataclass
class PerformanceMetrics:
    stt_latency: float  # Audio → text latency
    llm_latency: float  # Text → text generation latency
    tts_latency: float  # Text → audio latency
    end_to_end_latency: float  # Full round-trip latency
    vram_usage: Optional[float] = None  # VRAM in MB

class PerformanceMonitor:
    def __init__(self):
        self.metrics = []

    def measure_stt(self, start_time: float, end_time: float):
        """Record STT latency"""
        latency = end_time - start_time
        return PerformanceMetrics(
            stt_latency=latency,
            end_to_end_latency=latency
        )

    def measure_llm(self, metrics: PerformanceMetrics, start_time: float, end_time: float):
        """Record LLM latency"""
        metrics.llm_latency = end_time - start_time
        metrics.end_to_end_latency = metrics.stt_latency + metrics.llm_latency
        return metrics

    def measure_tts(self, metrics: PerformanceMetrics, start_time: float, end_time: float):
        """Record TTS latency"""
        metrics.tts_latency = end_time - start_time
        metrics.end_to_end_latency = (
            metrics.stt_latency + metrics.llm_latency + metrics.tts_latency
        )
        return metrics

    def record(self, metrics: PerformanceMetrics):
        """Store metrics"""
        self.metrics.append(metrics)

    def get_average_latencies(self) -> dict:
        """Get average latencies"""
        if not self.metrics:
            return {}

        import statistics
        return {
            "avg_stt": statistics.mean(m.stt_latency for m in self.metrics),
            "avg_llm": statistics.mean(m.llm_latency for m in self.metrics),
            "avg_tts": statistics.mean(m.tts_latency for m in self.metrics),
            "avg_e2e": statistics.mean(m.end_to_end_latency for m in self.metrics),
        }
```

### Error Recovery

```python
class ErrorRecovery:
    def __init__(self, max_retries: int = 3):
        self.max_retries = max_retries

    def with_retry(self, func, *args, **kwargs):
        """Execute function with retry logic"""
        last_error = None

        for attempt in range(self.max_retries):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                last_error = e
                print(f"Attempt {attempt + 1} failed: {e}")

                # Implement backoff strategy
                if attempt < self.max_retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff

        raise last_error

    def graceful_degradation(self, failure_type: str):
        """Handle failures by degrading functionality"""

        if failure_type == "stt_unavailable":
            print("STT unavailable, switching to backup")
            # Switch to Whisper Turbo
            return "whisper_turbo"

        elif failure_type == "llm_unavailable":
            print("LLM unavailable, using basic responses")
            # Use simple rule-based responses
            return "basic_responses"

        elif failure_type == "tts_unavailable":
            print("TTS unavailable, using text display")
            # Display text on screen instead of audio
            return "text_display"

        return None
```

---

## CLI Implementation Patterns

### Audio Capture

```python
import sounddevice as sd
import numpy as np
from rich.console import Console

console = Console()

class AudioCapture:
    def __init__(self, sample_rate: int = 16000, channels: int = 1):
        self.sample_rate = sample_rate
        self.channels = channels
        self.stream = None
        self.recording = False

    def start_recording(self):
        """Start recording from microphone"""
        try:
            self.stream = sd.InputStream(
                samplerate=self.sample_rate,
                channels=self.channels,
                dtype=np.float32
            )
            self.stream.start()
            self.recording = True
            console.print("[green]✓ Recording started")
        except sd.PortAudioError as e:
            console.print(f"[red]✗ Audio error: {e}")
            raise

    def stop_recording(self) -> np.ndarray:
        """Stop recording and return audio data"""
        if not self.stream:
            return np.array([])

        self.stream.stop()
        self.stream.close()
        self.recording = False
        console.print("[green]✓ Recording stopped")

        # Return captured data
        return np.array([])  # Simplified

    def read_chunk(self, chunk_size: int) -> np.ndarray:
        """Read audio chunk"""
        if not self.stream or not self.recording:
            return np.array([])

        data, overflow = self.stream.read(chunk_size)

        if overflow:
            console.print("[yellow]⚠ Audio overflow detected")

        return data
```

### Status Management with Rich

```python
from rich.console import Console
from rich.status import Status
from rich.panel import Panel
from rich.text import Text

class StatusManager:
    def __init__(self):
        self.console = Console()

    def show_spinner(self, message: str):
        """Display spinner status"""
        return self.console.status(f"[bold green]{message}", spinner="dots")

    def show_panel(self, message: str, style: str = "bold blue"):
        """Display panel message"""
        panel = Panel(Text(message, style=style))
        self.console.print(panel)

    def show_success(self, message: str):
        """Show success message"""
        self.console.print(f"[green]✓ {message}")

    def show_error(self, message: str):
        """Show error message"""
        self.console.print(f"[red]✗ {message}")

    def show_warning(self, message: str):
        """Show warning message"""
        self.console.print(f"[yellow]⚠ {message}")
```

### Clipboard Integration

```python
import subprocess

class ClipboardManager:
    def __init__(self, primary: str = "clipman"):
        self.primary = primary

    def copy(self, text: str) -> bool:
        """Copy text to clipboard with fallback"""

        # Try clipman first
        if self.primary == "clipman":
            try:
                subprocess.run(
                    ["clipman", "copy", text],
                    check=True,
                    timeout=5
                )
                return True
            except Exception:
                pass

        # Fallback to wl-clipboard
        try:
            process = subprocess.Popen(
                ["wl-copy"],
                stdin=subprocess.PIPE
            )
            process.communicate(input=text.encode(), timeout=5)
            return True
        except Exception as e:
            print(f"[red]Clipboard copy failed: {e}")
            return False
```

### Configuration Management

```python
import yaml
from pathlib import Path
from dataclasses import dataclass

@dataclass
class VoiceSTTConfig:
    stt_engine: str = "moonshine"
    language: str = "auto"
    sample_rate: int = 16000
    auto_copy_to_clipboard: bool = True
    chunk_duration_ms: int = 500

class ConfigLoader:
    def __init__(self, config_path: Path):
        self.config_path = config_path

    def load(self) -> VoiceSTTConfig:
        """Load configuration from file"""
        if not self.config_path.exists():
            return VoiceSTTConfig()

        with open(self.config_path) as f:
            data = yaml.safe_load(f)
            return VoiceSTTConfig(**data)

    def save(self, config: VoiceSTTConfig):
        """Save configuration to file"""
        self.config_path.parent.mkdir(parents=True, exist_ok=True)

        with open(self.config_path, "w") as f:
            yaml.dump(config.__dict__, f)
```

---

## Audio Processing Implementation

### VAD Parameters

```python
from dataclasses import dataclass

@dataclass
class VADConfig:
    min_speech_duration_ms: int = 250
    min_silence_duration_ms: int = 500
    speech_pad_ms: int = 100
    threshold: float = 0.5

VAD_CONFIGS = {
    "aggressive": VADConfig(100, 250, 50, 0.7),
    "normal": VADConfig(250, 500, 100, 0.5),
    "lenient": VADConfig(500, 1000, 150, 0.3)
}
```

### Audio Buffer Management

```python
from collections import deque
import numpy as np

class AudioBuffer:
    def __init__(self, max_size_ms: int = 5000, sample_rate: int = 16000):
        self.max_size = max_size_ms * sample_rate // 1000
        self.buffer = deque(maxlen=self.max_size)
        self.sample_rate = sample_rate

    def add(self, audio: np.ndarray):
        """Add audio to buffer"""
        for sample in audio:
            self.buffer.append(sample)

    def get_recent(self, duration_ms: int) -> np.ndarray:
        """Get recent audio segment"""
        size = duration_ms * self.sample_rate // 1000
        return np.array(list(self.buffer)[-size:])

    def clear(self):
        """Clear buffer"""
        self.buffer.clear()
```

### Noise Suppression

```python
import subprocess

def setup_noise_suppression():
    """Setup noise suppression with PipeWire"""
    try:
        # Check if easyeffects is available
        subprocess.run(
            ["which", "easyeffects"],
            check=True,
            capture_output=True
        )

        # Enable noise suppression
        subprocess.run([
            "pactl",
            "load-module",
            "module-easyeffects"
        ], check=True)

        return True
    except subprocess.CalledProcessError:
        return False
```

---

## TTS Integration Patterns

### TTS Base Interface

```python
from abc import ABC, abstractmethod

class BaseTTS(ABC):
    @abstractmethod
    def synthesize(self, text: str) -> tuple[bytes, int]:
        """Synthesize speech from text"""
        pass

    @abstractmethod
    def synthesize_to_file(self, text: str, output_path: str):
        """Synthesize and save to file"""
        pass

    @abstractmethod
    def cleanup(self):
        """Cleanup resources"""
        pass
```

### TTS Engine Factory

```python
class TTSEngineFactory:
    @staticmethod
    def create(engine_type: str, **kwargs) -> BaseTTS:
        """Create TTS engine instance"""

        if engine_type == "chatterbox":
            return ChatterboxSynthesizer(**kwargs)
        elif engine_type == "kokoro":
            return KokoroSynthesizer(**kwargs)
        elif engine_type == "coqui":
            return CoquiSynthesizer(**kwargs)
        else:
            raise ValueError(f"Unknown TTS engine: {engine_type}")
```

---

## LLM Integration Patterns

### LLM Base Interface

```python
from abc import ABC, abstractmethod

class BaseLLM(ABC):
    @abstractmethod
    def generate(self, prompt: str, stream: bool = True):
        """Generate response"""
        pass

    @abstractmethod
    def generate_sync(self, prompt: str) -> str:
        """Generate response synchronously"""
        pass

    @abstractmethod
    def cleanup(self):
        """Cleanup resources"""
        pass
```

### LLM Backend Factory

```python
class LLMBackendFactory:
    @staticmethod
    def create(backend_type: str, **kwargs) -> BaseLLM:
        """Create LLM backend instance"""

        if backend_type == "ollama":
            return OllamaClient(**kwargs)
        elif backend_type == "llama.cpp":
            return LlamaCppClient(**kwargs)
        elif backend_type == "vllm":
            return VLLMClient(**kwargs)
        else:
            raise ValueError(f"Unknown LLM backend: {backend_type}")
```

---

## Framework Integration Patterns

### Pipecat Pipeline Builder

```python
from pipecat import Pipeline, processor

class VoicePipelineBuilder:
    def __init__(self):
        self.pipeline = Pipeline()

    def add_microphone(self):
        """Add microphone input"""
        self.pipeline.join([processor.user_audio_frame_processor()])

    def add_stt(self, service: str, model: str, **options):
        """Add speech-to-text"""
        stt = processor.STTProcessor(service=service, model=model, options=options)
        self.pipeline.join([stt])

    def add_llm(self, service: str, model: str, system_prompt: str = ""):
        """Add LLM processing"""
        llm = processor.LLMProcessor(
            service=service,
            model=model,
            system_prompt=system_prompt
        )
        self.pipeline.join([llm])

    def add_tts(self, service: str, voice: str, **options):
        """Add text-to-speech"""
        tts = processor.TTSProcessor(service=service, voice=voice, options=options)
        self.pipeline.join([tts])

    def add_audio_output(self):
        """Add audio output"""
        self.pipeline.join([processor.AudioFrameProcessor()])

    def build(self) -> Pipeline:
        """Return built pipeline"""
        return self.pipeline
```

### Transport Handlers

```python
from pipecat.transports.websocket.server import WebSocketServerTransport, Params

class WebSocketTransport:
    def __init__(self, host: str = "0.0.0.0", port: int = 8765):
        self.transport = WebSocketServerTransport(
            params=Params(audio_frame_size_bytes=4096, sample_rate=24000),
            server=ServerTransport(
                host=host,
                port=port,
                uri="/ws",
                ping_interval=20
            )
        )

    async def run_server(self, pipeline: Pipeline):
        """Run WebSocket server with pipeline"""
        from fastapi import FastAPI, WebSocket

        app = FastAPI()

        @app.websocket("/ws")
        async def websocket_endpoint(websocket: WebSocket):
            await websocket.accept()

            while True:
                # Receive audio frames
                audio_data = await websocket.receive_bytes()

                # Send audio responses back
                await websocket.send_bytes(audio_data)

        # Start FastAPI server
        import uvicorn
        uvicorn.run(app, host="0.0.0.0", port=8765)
```

---

## System Integration

### Systemd User Service

```ini
[Unit]
Description=Voice STT Daemon
After=graphical-session.target hyprland.target pipewire.service
Wants=hyprland.target pipewire.service

[Service]
Type=simple
ExecStart=/usr/local/bin/voice-stt-daemon
Restart=on-failure
RestartSec=5
StandardOutput=journal+syslog

[Install]
WantedBy=default.target
```

### Socket Activation

```ini
[Unit]
Description=STT Daemon Socket

[Socket]
ListenStream=%t/stt/daemon.sock

[Install]
WantedBy=voice-stt.service
```

### Hyprland Integration

**File**: `~/.config/hypr/conf/bindings/voice-stt.conf`
```conf
# ============================================================================
# Voice STT - Speech-to-Text Transcription
# ============================================================================

# Toggle transcription: Super + T
bindd = SUPER, T, Toggle STT transcription, exec, voice-stt toggle

# Start conversation mode: Super + Shift + C
bindd = SUPER SHIFT, C, Start conversation, exec, voice-stt conversation

# Stop conversation: Escape (when in conversation mode)
bindd = , Escape, Stop conversation, exec, voice-stt stop

# Volume controls for TTS output
binde = , XF86AudioRaiseVolume, Increase TTS volume, exec, voice-stt volume +10
binde = , XF86AudioLowerVolume, Decrease TTS volume, exec, voice-stt volume -10
```

### Waybar Status Indicator

```json
"custom/stt": {
    "format": "🎤 {}",
    "exec": "voice-stt status",
    "interval": 1,
    "signal": 10
}
```

---

## Summary

This document provides comprehensive implementation patterns and code examples for all future phases of the Voice STT project:

**Phase 2**: Enhanced STT (Whisper backup, streaming output, session saving)
**Phase 3**: Two-Way Conversation (TTS, LLM, Pipecat, memory)
**Phase 4**: Advanced Features (TUI, RAG, vision, multi-agent)
**Phase 5**: Production Optimization (monitoring, error recovery, testing)

**Next Steps**:
1. Complete Phase 1 implementation (see `VOICE_STT_IMPLEMENTATION_PLAN.md`)
2. Review Phase 2+ requirements and priorities
3. Begin Phase 2 implementation when Phase 1 is stable

---

**References**

- Chatterbox: https://huggingface.co/ResembleAI/chatterbox
- Kokoro: https://github.com/hexgrad/kokoro
- Ollama: https://docs.ollama.com
- llama.cpp: https://github.com/ggml-org/llama.cpp
- Pipecat: https://github.com/pipecat-ai/pipecat
- LangChain: https://github.com/langchain-ai/langchain
- LlamaIndex: https://github.com/run-llama/llama_index
- Rich: https://github.com/Textualize/rich
- Textual: https://github.com/Textualize/textual
- LanceDB: https://github.com/lancedb/lancedb
- Chroma: https://github.com/chroma-core/chroma
