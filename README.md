# System check: AI testing training

About 30 minutes on a Teams call with screen sharing. Go through the steps in order and
stop at the first one that does not work. That tells us which version of the hands-on
exercises will work on your laptops. Nothing here changes settings on your laptop, and
only step 6 installs something (into a throwaway folder, no admin rights needed).

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

**Step 4. Node.js and the npm registry.**

```
node --version
npm view promptfoo version
```

Works if: Node shows v20 or higher, and npm prints a version number.

**Step 5. Network check script.** Tests which AI providers and package sources are
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

**Step 6. Python and the PyPI package index.**

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

## If there is time

Repeat steps 1, 4 and 5 on VPN (or on the bank network, whichever was not used first).
