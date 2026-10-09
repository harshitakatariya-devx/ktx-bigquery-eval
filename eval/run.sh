#!/bin/zsh
# Usage: eval/run.sh <run-name> [question-number ...]   (default: all questions)
# Asks each question in a fresh, locked-down Claude Code session (only ktx MCP tools; no files, shell or web)
# and writes the answer, ktx tool calls and timing to eval/runs/<run-name>/.
set -e
EVAL=${0:A:h}
PROJECT=${EVAL:h}
RUN=$EVAL/runs/${1:?usage: eval/run.sh <run-name> [question-number ...]}
shift
QUESTIONS=("${(@f)$(<$EVAL/questions.txt)}")
NUMBERS=(${@:-$(seq 1 ${#QUESTIONS})})
mkdir -p $RUN
cd $PROJECT

for N in $NUMBERS; do
  Q=${QUESTIONS[$N]}
  ID=$(printf "q%02d" $N)
  START=$(python3 -c 'import time; print(int(time.time()*1000))')
  claude -p "Use ktx: $Q" \
    --output-format json --no-session-persistence \
    --setting-sources project,local \
    --strict-mcp-config --mcp-config .mcp.json \
    --allowedTools "mcp__ktx__*" \
    --disallowedTools "Read,Glob,Grep,Bash,Edit,Write,NotebookEdit,WebFetch,WebSearch,Agent,Task" \
    < /dev/null > $RUN/$ID.json 2> $RUN/$ID.stderr
  END=$(python3 -c 'import time; print(int(time.time()*1000))')
  [[ -s $RUN/$ID.stderr ]] || rm -f $RUN/$ID.stderr

  ktx mcp logs 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | python3 -c "
import sys, json
for line in sys.stdin:
    i = line.find('{')
    if i < 0: continue
    try: d = json.loads(line[i:])
    except ValueError: continue
    if $START <= d.get('time', 0) <= $END and d.get('msg') == 'tool.start':
        print(json.dumps({'tool': d.get('tool'), 'params': d.get('params')}))
" > $RUN/$ID.tools.jsonl

  python3 - $RUN/$ID.json $RUN/$ID.tools.jsonl "$Q" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
tools = [json.loads(l)['tool'] for l in open(sys.argv[2])]
print(f"{sys.argv[3]}\n  {d.get('duration_ms', 0) / 1000:.0f}s  turns={d.get('num_turns')}  "
      f"cost_usd={d.get('total_cost_usd', 0):.3f}  blocked={len(d.get('permission_denials') or [])}  tools={tools}")
PY
done
