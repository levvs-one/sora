#!/usr/bin/env python3
"""Index-poisoning forensic monitor.

Polls .git/index of sora, sora-legacy and a private canary repo; on any
index change records time, sha256 and a staged-vs-HEAD delta summary
(read-only: GIT_OPTIONAL_LOCKS=0 everywhere). Concurrently scans /proc
for git processes and logs pid/ppid/ancestor cmdlines + GIT_INDEX_FILE.
Every 120s makes a canary commit in the canary repo (a fresh commit in a
repo no department knows about: if it gets staged-reverted, the actor is
environmental, not an agent following the swarm's commits).
"""
import hashlib, os, subprocess, sys, time

REPOS = {
    "sora": "/home/hatch/workspace/bug-hunt/sora",
    "legacy": "/home/hatch/workspace/bug-hunt/sora-legacy",
    "canary": "/home/hatch/workspace/bug-hunt/forensics-canary",
}
LOG = "/home/hatch/workspace/bug-hunt/reports/forensics-live/monitor.log"
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
logf = open(LOG, "a", buffering=1)

def ts():
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ".%03d" % int((time.time() % 1) * 1000)

def log(msg):
    logf.write(f"{ts()} {msg}\n")

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()[:16]

def head_tree(repo):
    """path -> blob sha for HEAD tree of repo."""
    try:
        out = subprocess.run(["git", "-C", repo, "ls-tree", "-r", "-z", "HEAD"],
                             capture_output=True, env=ENV, timeout=20).stdout
        tree = {}
        for rec in out.split(b"\0"):
            if not rec:
                continue
            meta, p = rec.split(b"\t", 1)
            tree[p.decode("utf-8", "replace")] = meta.split()[2].decode()
        return tree
    except Exception as e:
        log(f"ls-tree failed {repo}: {e}")
        return {}

def index_entries(repo):
    """path -> blob sha staged in the index."""
    try:
        out = subprocess.run(["git", "-C", repo, "ls-files", "--stage", "-z"],
                             capture_output=True, env=ENV, timeout=20).stdout
        ent = {}
        for rec in out.split(b"\0"):
            if not rec:
                continue
            meta, p = rec.split(b"\t", 1)
            ent[p.decode("utf-8", "replace")] = meta.split()[1].decode()
        return ent
    except Exception as e:
        log(f"ls-files failed {repo}: {e}")
        return {}

def head_ref(repo):
    try:
        with open(os.path.join(repo, ".git", "HEAD")) as f:
            ref = f.read().strip()
        if ref.startswith("ref: "):
            with open(os.path.join(repo, ".git", ref[5:].strip())) as f:
                return f.read().strip()[:12]
        return ref[:12]
    except Exception:
        return "?"

state = {}
trees = {}
heads = {}
for name, repo in REPOS.items():
    idx = os.path.join(repo, ".git", "index")
    try:
        st = os.stat(idx)
        state[name] = (st.st_mtime_ns, st.st_size, sha256(idx))
    except FileNotFoundError:
        state[name] = None
    trees[name] = head_tree(repo)
    heads[name] = head_ref(repo)
log(f"=== monitor started; baseline heads={heads} ===")

seen_procs = {}  # (pid, starttime) -> True
def scan_procs():
    try:
        pids = [p for p in os.listdir("/proc") if p.isdigit()]
    except Exception:
        return
    for p in pids:
        try:
            with open(f"/proc/{p}/stat", "rb") as f:
                stat = f.read().decode("utf-8", "replace")
            starttime = stat.rsplit(")", 1)[1].split()[19]
            key = (p, starttime)
            if key in seen_procs:
                continue
            with open(f"/proc/{p}/cmdline", "rb") as f:
                cmd = f.read().replace(b"\0", b" ").decode("utf-8", "replace").strip()
            if not cmd:
                continue
            low = cmd.split()[0]
            is_git = os.path.basename(low).startswith("git") or " git " in cmd[:200] or cmd.startswith("git ")
            if not is_git:
                # keep bash procs too if they invoke git visibly; cheap filter:
                if "git " not in cmd and "git-" not in cmd:
                    seen_procs[key] = True
                    continue
            seen_procs[key] = True
            if len(seen_procs) > 20000:
                seen_procs.clear()
            env = ""
            try:
                with open(f"/proc/{p}/environ", "rb") as f:
                    for kv in f.read().split(b"\0"):
                        if kv.startswith(b"GIT_INDEX_FILE=") or kv.startswith(b"GIT_DIR="):
                            env += kv.decode("utf-8", "replace") + " "
            except Exception:
                pass
            cwd = ""
            try:
                cwd = os.readlink(f"/proc/{p}/cwd")
            except Exception:
                pass
            ppid = stat.rsplit(")", 1)[1].split()[1]
            ancestors = []
            cur = ppid
            for _ in range(4):
                try:
                    with open(f"/proc/{cur}/cmdline", "rb") as f:
                        ac = f.read().replace(b"\0", b" ").decode("utf-8", "replace").strip()
                    with open(f"/proc/{cur}/stat", "rb") as f:
                        ast = f.read().decode("utf-8", "replace")
                    nppid = ast.rsplit(")", 1)[1].split()[1]
                except Exception:
                    break
                if ac:
                    ancestors.append(f"[{cur}] {ac[:400]}")
                if nppid == cur or nppid == "0":
                    break
                cur = nppid
            log(f"PROC pid={p} ppid={ppid} cwd={cwd} env={env.strip()} cmd={cmd[:400]}")
            for a in ancestors:
                log(f"  ancestor: {a}")
        except Exception:
            continue

canary_last = time.time()
iteration = 0
while True:
    iteration += 1
    for name, repo in REPOS.items():
        idx = os.path.join(repo, ".git", "index")
        try:
            st = os.stat(idx)
            cur = (st.st_mtime_ns, st.st_size)
        except FileNotFoundError:
            cur = None
        prev = state.get(name)
        if prev is None or cur is None or cur != (prev[0], prev[1]):
            newsha = sha256(idx) if cur else None
            href = head_ref(repo)
            head_changed = href != heads[name]
            if head_changed:
                heads[name] = href
                trees[name] = head_tree(repo)
            delta = ""
            if name != "canary" and prev is not None:
                ent = index_entries(repo)
                tree = trees[name]
                changed = [p for p in set(ent) | set(tree) if ent.get(p) != tree.get(p)]
                if changed:
                    kinds = []
                    dels = sum(1 for p in changed if p not in ent)
                    adds = sum(1 for p in changed if p not in tree)
                    mods = len(changed) - dels - adds
                    delta = f" staged-vs-HEAD: {len(changed)} paths (mod={mods} del={dels} add={adds}) e.g. {changed[:6]}"
                else:
                    delta = " staged-vs-HEAD: clean"
            log(f"INDEX {name}: sha {prev[2] if prev else '-'} -> {newsha} head={href}{' (HEAD moved)' if head_changed else ''}{delta}")
            state[name] = (cur[0], cur[1], newsha) if cur else None
    if iteration % 4 == 0:
        scan_procs()
    # canary commit every 120 s
    if time.time() - canary_last > 120:
        canary_last = time.time()
        try:
            repo = REPOS["canary"]
            with open(os.path.join(repo, "canary.txt"), "a") as f:
                f.write(f"tick {int(canary_last)}\n")
            subprocess.run(["git", "-C", repo, "add", "canary.txt"], env=ENV, timeout=20)
            subprocess.run(["git", "-C", repo, "commit", "-qm", f"canary tick {int(canary_last)}"],
                           env=ENV, timeout=20)
            log(f"CANARY committed tick {int(canary_last)} head={head_ref(repo)}")
        except Exception as e:
            log(f"canary commit failed: {e}")
    time.sleep(0.05)
