## Running with Docker (Recommended for Local Development)

This project can be run using Docker and Docker Compose for a consistent development environment.

**Prerequisites:**

*   Docker: [Install Docker](https://docs.docker.com/get-docker/)
*   Docker Compose: (Usually included with Docker Desktop)

**Setup:**

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```

2.  **Create an environment file:**
    Copy the example environment file and customize it if needed:
    ```bash
    cp .envexample .env
    ```
    **Important:** For Docker Compose, ensure the following settings are in your `.env` file:
    *   `OLLAMA_URL=http://ollama:11434` (to connect to the Ollama service in Docker)
    *   `GHIDRA_MCP_EXTENDED_URL=http://localhost:8081` (the Python MCP server will be available on host's port 8081)
    *   `GHIDRA_MCP_URL=http://host.docker.internal:8080` (if your main Ghidra instance is running on your host machine and you want the application *inside Docker* to connect to it. For Linux, you might need to configure Docker networking differently or use `http://<your-host-ip>:8080`). Alternatively, `http://localhost:8080` if you intend to run the CLI *from your host* against the Dockerized `ghidra_mcp_server.py` and your Ghidra instance is also on the host. For simplicity, `host.docker.internal` is a good default for Docker Desktop users.

3.  **Build and start the services:**
    ```bash
    docker-compose up --build -d
    ```
    This will build the Docker image for the application, pull the Ollama image, and start both services.

4.  **Pull an Ollama Model:**
    After the services are up, you need to pull an Ollama model into the Ollama container. For example, to pull `llama3.1` (as recommended in `.envexample`):
    ```bash
    docker-compose exec ollama ollama pull llama3.1
    ```
    You can replace `llama3.1` with any other model you wish to use. List available models with `docker-compose exec ollama ollama list`.

**Usage:**

*   **Ghidra MCP Extended Server:**
    The Python-based Ghidra MCP extended server (`ghidra_mcp_server.py`) will automatically start and be available on `http://localhost:8081` on your host machine.

*   **Interactive CLI (main.py):**
    To run the interactive CLI (`src/main.py`), execute the following command:
    ```bash
    docker-compose exec oghidra python src/main.py --interactive
    ```
    You can also use other command-line arguments for `main.py` as needed:
    ```bash
    docker-compose exec oghidra python src/main.py --query "your query"
    ```

*   **Accessing Ollama:**
    The Ollama service is available at `http://localhost:11434` on your host machine.

*   **Accessing Main Ghidra Instance:**
    The Docker setup for *this* project does not include the main Ghidra application/server itself (typically on port 8080). You are expected to have your Ghidra instance running separately (e.g., on your host machine or another server). Configure `GHIDRA_MCP_URL` in your `.env` file to point to its location.

**Development:**

*   The application code (current directory) is mounted into the `oghidra` container. Changes to your local files will be reflected automatically in the container, usually requiring a restart of the specific process if it's long-running (the `ghidra_mcp_server.py` run by `CMD` will restart if you `docker-compose restart oghidra`, or for `main.py` you just rerun the `exec` command).
*   To see logs:
    ```bash
    docker-compose logs oghidra
    docker-compose logs ollama
    ```
*   To stop the services:
    ```bash
    docker-compose down
    ```
*   To stop and remove volumes (e.g., to clear Ollama models or application data):
    ```bash
    docker-compose down -v
    ```

---
(Original README content follows below)

# OGhidra - Ollama-GhidraMCP Bridge

OGhidra bridges the gap between Large Language Models (LLMs) running via Ollama and the Ghidra reverse engineering platform through the GhidraMCP API. It enables using natural language to interact with Ghidra for binary analysis tasks.

## OGhidra Architecture

![OGhidra](https://github.com/user-attachments/assets/21d2ec49-a814-407f-b56b-50fdb59ccab5)


## Finding Malware with the 'run-tool analyze_function()' feature

Inspecting function with strange string
![momento-0-malwarefind](https://github.com/user-attachments/assets/7779d9a4-316e-49bf-ada0-4468d9bd0bc1)

Inspecting strange function
![momento-2-malwarefind](https://github.com/user-attachments/assets/0f2ac533-3d19-4b13-9757-a8e0d1fb8f0b)

Uh oh that doesn't sound good
![momento-3-malwarefind](https://github.com/user-attachments/assets/63963014-566b-47eb-9407-b2270ef9884e)

Ask AI to summarize our findings
![momento-4-malwarefind](https://github.com/user-attachments/assets/5881fee8-6432-4355-9f94-a76061434d6d)


## Key Features

*   **Dual API Server Architecture**: Uses the original GhidraMCP server and an extended Flask-based server for comprehensive API coverage.
*   **Multi-Phase AI Processing**: Employs a Planning-Execution-Analysis workflow for structured interaction.
*   **Flexible Model Configuration**: Allows using different Ollama models for each processing phase.
*   **Command Normalization**: Improves compatibility with various LLMs by correcting command formats.
*   **Session Memory & Caching**: Features session history, Retrieval-Augmented Generation (RAG), and Cache-Augmented Generation (CAG) for contextual awareness and knowledge persistence.
*   **Interactive & Scriptable**: Can be used interactively or integrated into scripts.

## Architecture Overview

OGhidra uses a streamlined three-phase approach:

1.  **Planning Phase**: An LLM analyzes the user's query and generates a structured plan using Ghidra tools.
2.  **Tool Calling Phase (Execution)**: The plan is deterministically parsed, and the corresponding GhidraMCP client methods are called to interact with the Ghidra instance(s). This phase uses a Python function (`_parse_and_execute_plan` in `src/bridge.py`) instead of an LLM.
3.  **Analysis Phase**: An LLM analyzes the results gathered from Ghidra and provides a comprehensive response.

### Dual API Servers

*   **Original GhidraMCP Server**: Typically runs on `http://localhost:8080`. Provides core Ghidra functions.
*   **Extended API Server**: A Flask server (`src/ghidra_mcp_server.py`) running on `http://localhost:8081` (default). Implements functions defined in `ghidra_knowledge_cache/function_signatures.json`.
*   **Client Fallback**: The `GhidraMCPClient` (`src/ghidra_mcp_client.py`) attempts calls to the original server first and falls back to the extended server if needed.

### Key Implementation Classes

*   `Bridge`: Main class coordinating the multi-phase processing (`src/bridge.py`).
*   `OllamaClient`: Handles communication with the Ollama API (`src/ollama_client.py`).
*   `GhidraMCPClient`: Communicates with the GhidraMCP servers (`src/ghidra_mcp_client.py`).
*   `BridgeConfig`: Centralizes configuration management (`src/config.py`).
*   `MemoryManager`: Manages session history and RAG (`src/memory_manager.py`).
*   `CAGManager`: Manages Cache-Augmented Generation (`src/cag/manager.py`).

## 📹 OGhidra Tutorial Video

[![Installation and Tool Use Tutorial](https://img.youtube.com/vi/6Vopm0t1ZlY/0.jpg)](https://youtu.be/6Vopm0t1ZlY)


## Pre-installation 
Contact me at enochsurge@gmail.com for setup help. 

1.  **SETUP-GHIDRAMCP**
    *    Ghidra 11.3.2 (https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.3.2_build/ghidra_11.3.2_PUBLIC_20250415.zip)
    *    GhidraMCP (https://github.com/LaurieWired/GhidraMCP/releases/download/1.3/GhidraMCP-release-1-3.zip)
        *    Run Ghidra
        *    Select File -> Install Extensions
        *    Click the + button
        *    Select the GhidraMCP-1-2.zip (or your chosen version) from the downloaded release
        *    Restart Ghidra
        *    Make sure the GhidraMCPPlugin is enabled in File -> Configure -> Developer
        *    Optional: Configure the port in Ghidra with Edit -> Tool Options -> GhidraMCP HTTP Server
 2.  **OLLAMA-SERVER-INSTALLATION**
    *    Install Ollama
    *    Serve Ollamma service
    *    Pull Gemma3:27B


## Setup and Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd OGhidra-main
    ```
2.  **Set up Ghidra and GhidraMCP**: Follow the instructions for Ghidra and the GhidraMCP plugin to have the original server running (usually on port 8080).
3.  **Create a Python virtual environment (optional but recommended):**
    ```bash
    python -m venv venv
    source venv/bin/activate  # Linux/macOS
    .\venv\Scripts\activate    # Windows
    ```
4.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
5.  **Configure environment variables:**
    *   Copy `.envexample` to `.env`.
    *   Edit `.env` to set your Ollama endpoint (`OLLAMA_API_URL`), default model (`OLLAMA_MODEL`), and GhidraMCP server URLs (`GHIDRA_MCP_URL`, `GHIDRA_MCP_EXTENDED_URL`).
    *   Configure phase-specific models, memory, and CAG settings as needed (see below).


   ** After Installation **
 6.  *Run 'python main.py --interactive'
 7.  Check Health:


This will help identify if your Local OLLAMA and Local Ghidra Server are connected (Ghidra has to be open)
![image](https://github.com/user-attachments/assets/d9ea3b2b-d041-4642-8b61-ff8297e1120e)


**Interactive Mode:**

```bash
python src/main.py --interactive
```

See `README-MODELS.md` and `README-MODEL-SWITCHING.md` (now incorporated here) for more details on model selection recommendations.


## Interactive Mode Commands

When running OGhidra in interactive mode (`python src/main.py --interactive`), you have access to several commands to inspect and interact with the loaded binary:

*   **`run-tools analyze_function <function_name_or_address>`**: Decompiles and provides an analysis of the specified function. For example: `analyze_function FUN_00401230` or `analyze_function main`.
*   **`run-tools strings`**: Lists all discovered strings within the binary. You can then ask follow-up questions about specific strings.
*   **`run-tools imports`**: Displays a list of all imported functions and the libraries they belong to.
*   **`run-tools exports`**: Shows all exported symbols from the binary.
*   **`review_session`**: Allows you to review the commands and AI responses from the current interactive session.
*   **`cag`**: Displays the current status of Cache-Augmented Generation (CAG), including whether it's enabled and information about the knowledge and session caches. Use this to check if CAG is active and what context it's using.
*   **`health`**: Checks the operational status of the Ollama and GhidraMCP bridge connections.
*   **`tools`**: Lists available tools/commands that can be used.
*   **`models`**: Lists the Ollama models available to the bridge.
*   **`vector-store`**: (If RAG/vector embeddings are enabled) Provides information or options related to the vector store.
*   **`help`**: Shows a list of available interactive commands and their descriptions.
*   **`exit` / `quit`**: Exits the interactive mode.

These commands leverage the underlying GhidraMCP functionalities and the AI's analytical capabilities to provide insights into the binary.

**Single Query:**

```bash
python src/main.py "Your analysis query here"
```

## Example of hardcoded AI features: 


'run-tool list_imports()'

![listingimports](https://github.com/user-attachments/assets/f91cebb5-4ff6-4ddc-8d1f-a1db00b65625)
![listingimports2](https://github.com/user-attachments/assets/5eb8306e-1854-43a2-8400-c266e91bf97e)


'run-tool list_strings()'

![liststrings1](https://github.com/user-attachments/assets/c599f57a-392a-46e7-9de8-8a517ee85aba)
![liststrings2](https://github.com/user-attachments/assets/04198fcb-2e12-4e18-abc0-0ba3f82ccdb5)


## Configuration Details

Configuration is primarily managed via the `.env` file and command-line arguments.

### Models and Phases

*   Set the default model: `OLLAMA_MODEL=llama3`
*   Set phase-specific models (optional):
    *   `OLLAMA_MODEL_PLANNING=gemma3:27b`
    *   `OLLAMA_MODEL_ANALYSIS=gemma3:27b`
    *   (Note: The Execution phase uses deterministic Python code, not an LLM).
*   Use `--list-models` to see available Ollama models.
*   Phase-specific system prompts can also be set (e.g., `OLLAMA_SYSTEM_PROMPT_PLANNING`).

See `README-MODELS.md` and `README-MODEL-SWITCHING.md` (now incorporated here) for more details on model selection recommendations.

### Command Normalization

The system automatically normalizes command names (e.g., `decompileFunction` -> `decompile_function`) and parameters to improve compatibility with LLMs that don't strictly follow the required format. Normalizations are logged to the console.

See `README-COMMAND-NORMALIZATION.md` (now incorporated here) for details.

### Session Memory (History & RAG)

*   **Enable/Disable**: `SESSION_HISTORY_ENABLED=true` / `false`
*   **Storage Path**: `SESSION_HISTORY_PATH="data/ollama_ghidra_session_history.jsonl"`
*   **Max Sessions**: `SESSION_HISTORY_MAX_SESSIONS=1000`
*   **Vector Embeddings (RAG)**:
    *   `SESSION_HISTORY_USE_VECTOR_EMBEDDINGS=true` / `false`
    *   `SESSION_HISTORY_VECTOR_DB_PATH="data/vector_db"`
*   **Command Line:**
    *   `python src/main.py --check-memory`
    *   `python src/main.py --memory-stats`
    *   `python src/main.py --clear-memory`
    *   `python src/main.py --enable-vector-embeddings` / `--disable-vector-embeddings`
*   **Interactive Commands**: `memory-health`, `memory-stats`, `memory-clear`, `memory-vectors-on`, `memory-vectors-off`

See `src/README_MEMORY.md` (now incorporated here) for implementation details.

### Cache-Augmented Generation (CAG)

CAG provides persistent, cached knowledge (Ghidra commands, workflows) and session context (decompiled functions, renames) without real-time retrieval.

*   **Enable/Disable**: `CAG_ENABLED=true` / `false`
*   **Knowledge Cache**: `CAG_KNOWLEDGE_CACHE_ENABLED=true` / `false`
*   **Session Cache**: `CAG_SESSION_CACHE_ENABLED=true` / `false`
*   **Token Limit**: `CAG_TOKEN_LIMIT=2000`
*   **Command Line**: `python src/main.py --disable-cag`
*   **Interactive Command**: `cag` (shows status)

Knowledge Base Files:
*   `ghidra_knowledge_cache/function_signatures.json`
*   `ghidra_knowledge_cache/common_workflows.json` (if exists)
*   `ghidra_knowledge_cache/binary_patterns.json` (if exists)
*   `ghidra_knowledge_cache/analysis_rules.json` (if exists)

See `README-CAG.md` (now incorporated here) for more details.

## Testing

*   Below is AI-generated nonsense just run 'python main.py --interactive' and type 'health' to check whats available and whats missing. 
*   **Extended API Server Tests**: `python -m unittest src/test_extended_api.py` (Ensure the extended server is running).
*   **Bridge/Normalization Tests**: Check `tests/` directory (e.g., `test_command_normalization.py`, `test_bridge.py`). Run relevant tests using `unittest`.
*   **Memory Sample Data**: `python src/generate_sample_data.py` (See memory docs for options).
