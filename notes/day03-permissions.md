## Bug DVPS-12: Script not executable

**Symptom:** `./scripts/day02/fs_audit.sh` returns `Permission denied`

**Root Cause:**
File permissions were 644 (rw-r--r--).
The execute bit (x) was missing for the owner.

**Why this happens in practice:**
- `git` does NOT preserve all permission bits when cloning on some systems.
- Automated file creation tools often default to 644.
- Copying files with `cp` without `-p` flag drops execute bit.

**Fix:**
`chmod 750 scripts/day02/fs_audit.sh`

**Prevention:**
- Always verify with `ls -la` after deploying scripts.
- Add permission check to deployment scripts.
- Git does track the execute bit (x) for the owner — check with `git ls-files --stage`.
