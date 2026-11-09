# System check

About 20 minutes on a Teams call with screen sharing. Please do it twice if you can: once
on the bank network and once on VPN. Nothing here changes settings on your laptop. Stages 0
and 1 install nothing. Stop at the first stage that does not work.

Files: `chat-check.txt` and `chat-check-full-manual.txt` (stage 0), `check.ps1` (Windows),
`check.sh` (Mac), `promptfooconfig.yaml` (stage 2).

Get them with git:

```
git clone https://github.com/test-solutions-gmbh/ai-testing-training-system-check.git
cd ai-testing-training-system-check
```

Without git: on the GitHub page, **Code > Download ZIP**, then unzip into a folder such as
`Documents\system-check`.

## Stage 0: chat AI and Excel (5 minutes, nothing to install)

1. Open the chat AI your bank allows (for example Microsoft Copilot or ChatGPT).
2. Open `chat-check.txt`. Paste prompt 1 into the chat and send it.
3. Start a new chat. Paste prompt 2, add the answer from step 2 at the end, send it.
4. Optional: paste all of `chat-check-full-manual.txt` into a new chat. This shows whether
   a long text (about 45,000 characters) fits into one message.
5. Open the Excel file shared in the Teams chat and type something into a cell.

## Stage 1: network and tools (5 minutes, installs nothing)

**Windows**, in PowerShell, from the folder with the files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\check.ps1
```

If that is refused because of a script policy, use:

```powershell
Get-Content .\check.ps1 -Raw | Invoke-Expression
```

**Mac**, in Terminal, from the folder with the files:

```bash
bash check.sh
```

The result is saved to `system-check-result.txt` and copied to the clipboard. Paste it
into the Teams chat.

To include one real model call, set the key we give you in the call first
(Windows: `$env:OPENROUTER_API_KEY="sk-or-..."`, Mac: `export OPENROUTER_API_KEY=sk-or-...`)
and run the check again. The key has a tiny spending limit and is deleted after the call.

## Stage 2: promptfoo (5 minutes, needs Node 20 or later)

Skip if Node is not installed. Same terminal, key set as above:

```
npx -y promptfoo@0.124.1 eval --no-cache --output results.html
```

Expected: `1 passed`. Then open `results.html` in the browser.

## Stage 3: Python and a local web app (5 to 10 minutes, needs Python 3.12 or uv)

Skip if neither Python nor uv is installed. This installs Streamlit into a throwaway
folder (about 100 MB, no admin rights needed) and starts its demo app:

**Windows**

```powershell
python -m venv st-check
.\st-check\Scripts\python -m pip install streamlit
.\st-check\Scripts\streamlit hello
```

**Mac**

```bash
python3 -m venv st-check
./st-check/bin/python -m pip install streamlit
./st-check/bin/streamlit hello
```

A browser tab opens on `http://localhost:8501`. Click one of the demos, then press Ctrl+C
in the terminal. Delete the `st-check` folder afterwards.

## Stage 4: Teams (2 minutes)

- Share your screen with the Streamlit or report page open
- Open the Excel file shared in the meeting chat and type something in a cell
