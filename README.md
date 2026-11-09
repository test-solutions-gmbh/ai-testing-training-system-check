# System check: AI testing training

Go through the steps in order and stop at the first one that does not work (in part B,
please run all three steps even if one fails). That tells us which version of the hands-on
exercises will work on your laptops. Nothing here changes settings on your laptop, and
only steps 4 and 5 install something (into your user folder, no admin rights needed).

All content is fictitious: a made-up customer-service chatbot for "SkyWay Airlines". No
bank or personal data is used.

## Get the files

```
git clone https://github.com/test-solutions-gmbh/ai-testing-training-system-check.git
cd ai-testing-training-system-check
```

## Part A: no installation needed

**Step 1. A chat AI answers a test prompt.**
Open the chat AI your bank allows (for example Microsoft Copilot or ChatGPT). Open
`chat-check.txt`, copy prompt 1 and send it.
Works if: an answer comes back.

**Step 2. The chat AI acts as a judge.**
Start a new chat. Copy prompt 2 from `chat-check.txt`, paste the answer from step 1 at the
end, and send it.
Works if: the first line says ACCEPTABLE or NOT ACCEPTABLE, followed by a reason.

**Step 3. Excel shared in Teams.**
Open the Excel file shared in the meeting chat and type something into a cell.
Works if: everyone in the call sees the edit.

## Part B: tools on the laptop

Use PowerShell on Windows (Git Bash works too), Terminal on Mac, inside the
`ai-testing-training-system-check` folder.

**Step 4. Node.js and promptfoo.** Downloads promptfoo (the open-source testing tool used
in the training) into your user folder, no admin rights needed, and runs one test. The
test uses no AI model and no API key.

```
node --version
npx -y promptfoo@0.124.1 eval --no-cache --output results.html
```

The first run downloads promptfoo and takes one to three minutes.

Works if: Node shows v20 or higher, and promptfoo ends with `1 passed`. Then open
`results.html` in the browser.

If PowerShell says that `npx.ps1` cannot be loaded because running scripts is disabled,
use `npx.cmd` instead of `npx`.

**Step 5. Python and the PyPI package index.**

Windows:

```
python --version
python -m venv st-check
.\st-check\Scripts\python -m pip install streamlit
```

Mac:

```
python3 --version
python3 -m venv st-check
./st-check/bin/python -m pip install streamlit
```

Works if: Python 3.12 or higher, and the install finishes without errors. Delete the
`st-check` folder afterwards.

**Step 6. Network check script.** Tests which AI providers and package sources are
reachable, and lists installed tools and proxy settings. Read-only.

- Windows (PowerShell or Git Bash):
  `powershell -NoProfile -ExecutionPolicy Bypass -File ./check.ps1`
  If scripts are blocked by policy, in PowerShell:
  `Get-Content .\check.ps1 -Raw | Invoke-Expression`
- Mac: `bash check.sh`

The result is saved to `system-check-result.txt` and copied to the clipboard. Please paste
it into the Teams chat.
Works if: "OpenAI API" or "Anthropic API" shows `OK` (HTTP 401 is fine, it means the
service was reached without a key).

**Step 7 The bank's own AI gateway.**

Ask IT:

1. Can we use the AI gateway for a training? If yes: its address, a
   key, and one model name.
2. Can 10 to 20 people use it at the same time?
3. Run some test queries against it:

If you have the address, key and model, run in PowerShell:

```
$env:OPENAI_BASE_URL="<gateway address>"
$env:OPENAI_API_KEY="<key>"
$env:GATEWAY_MODEL="<model name>"
npx -y promptfoo@0.124.1 eval -c promptfooconfig.gateway.yaml --no-cache
```

(Git Bash or Mac: `export OPENAI_BASE_URL="..."` and so on.)

Works if: `1 passed`.
