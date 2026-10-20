#!/usr/bin/env python3
"""Filter `git diff HEAD -- app/lib/l10n` to hunks containing only my keys.
Drops hunks touching sibling keys (extBg*, updateSignature*, updateStageVerify).
Prints the filtered unified diff to stdout."""
import re, subprocess, sys

SIBLING = re.compile(r'extBg[A-Z]|updateSignaturePending|updateManualSigWarning|updateStageVerify')

diff = subprocess.run(
    ['git', 'diff', 'HEAD', '--', 'app/lib/l10n'],
    capture_output=True, text=True, cwd='/home/hatch/workspace/bug-hunt/sora').stdout

out = []
cur_hunk = []
cur_sibling = False
in_hunk = False

def flush():
    if cur_hunk and not cur_sibling:
        out.extend(cur_hunk)

for line in diff.split('\n'):
    if line.startswith('diff --git'):
        flush(); cur_hunk = [line]; cur_sibling = False; in_hunk = False
    elif line.startswith('@@'):
        flush(); cur_hunk = [line]; cur_sibling = False; in_hunk = True
    elif line.startswith(('index ', '--- ', '+++ ', 'new file', 'old mode', 'new mode')):
        cur_hunk.append(line)
    elif in_hunk:
        cur_hunk.append(line)
        if line.startswith('+') and not line.startswith('+++') and SIBLING.search(line):
            cur_sibling = True
    else:
        cur_hunk.append(line)
flush()
sys.stdout.write('\n'.join(out))
