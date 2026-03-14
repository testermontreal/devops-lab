# Day 3 — Linux Permissions, Users & Sudo

## 📖 Module 1 — The Permission Model (Understanding File Permissions)

## chmod — Change Mode

<https://linuxize.com/post/chmod-command-in-linux/>

```bash
# Syntax: chmod [options] MODE FILE

# ── Numeric mode ──────────────────────────────────────────

# Set specific permissions (absolute)
chmod 755 scripts/day02/fs_audit.sh
# → rwxr-xr-x: owner runs it, group/others can read+execute

chmod 750 scripts/day02/fs_audit.sh
# → rwxr-x---: others have NO access (production default for scripts)

chmod 644 notes/day01-git.md
# → rw-r--r--: standard for config files and docs

chmod 600 ~/.ssh/id_ed25519_github
# → rw-------: private key must be readable ONLY by owner
# SSH will REFUSE to use the key if permissions are too open

chmod 700 ~/.ssh/
# → rwx------: SSH directory accessible only by owner

# ── Symbolic mode ─────────────────────────────────────────
# Format: [who][operator][permission]
# who:      u=user/owner, g=group, o=others, a=all
# operator: +=add, -=remove, ==set exactly

chmod +x scripts/day02/fs_audit.sh     # add execute for ALL
chmod u+x scripts/day02/fs_audit.sh    # add execute for owner only
chmod o-r notes/day01-git.md           # remove read from others
chmod a-x,u+x scripts/day03/audit.sh   # remove x from all, add x for owner

# ── Recursive ─────────────────────────────────────────────

chmod -R 750 scripts/        # apply 750 to scripts/ and everything inside
# WARNING: -R applies same permissions to files AND directories
# This is often wrong — directories need x to be traversable

# Safer approach:
find scripts/ -type f -exec chmod 640 {} \;   # files only
find scripts/ -type d -exec chmod 750 {} \;   # directories only

# Using the symbolic method:
find /var/www/my_website -type d -exec chmod u=rwx,go=rx {} \;
find /var/www/my_website -type f -exec chmod u=rw,go=r {} \;
```

## chown — Change Owner

<https://linuxize.com/post/linux-chown-command/>

```bash
# Syntax: chown [user][:group] FILE

# Change owner
sudo chown root /etc/myapp.conf

# Change owner AND group simultaneously
sudo chown deploy:devops /opt/app/

# Change group only (colon with no user)
sudo chown :devops scripts/

# Recursive
sudo chown -R deploy:devops /opt/app/

# Verify
ls -la /opt/app/
stat /opt/app/
```

---

# Users & Groups - Production-Like Setup

```bash
# ── User/group management ──────────────────────────────────────
sudo useradd --system --no-create-home --shell /usr/sbin/nologin deploy
sudo groupadd devops
sudo usermod --append --groups devops tester   # append! never forget -a
id username                     # show UID, GID, all groups
groups username                 # show all groups for user

```

&nbsp;

**List All Users with /etc/passwd**

```bash
less /etc/passwd

   1   │ root:x:0:0:root:/root:/bin/bash
   2   │ daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
   3   │ bin:x:2:2:bin:/bin:/usr/sbin/nologin
   4   │ sys:x:3:3:sys:/dev:/usr/sbin/nologin
   5   │ sync:x:4:65534:sync:/bin:/bin/sync
   6   │ games:x:5:60:games:/usr/games:/usr/sbin/nologin
   7   │ man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
   8   │ lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
   9   │ mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
  10   │ news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
  11   │ uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
  12   │ proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
  13   │ www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
  14   │ backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
  15   │ list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
  16   │ irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
  17   │ _apt:x:42:65534::/nonexistent:/usr/sbin/nologin
  18   │ nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
  19   │ systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
  20   │ systemd-timesync:x:996:996:systemd Time Synchronization:/:/usr/sbin/nologin
  21   │ dhcpcd:x:100:65534:DHCP Client Daemon,,,:/usr/lib/dhcpcd:/bin/false
  22   │ messagebus:x:101:101::/nonexistent:/usr/sbin/nologin
  23   │ syslog:x:102:102::/nonexistent:/usr/sbin/nologin
  24   │ systemd-resolve:x:991:991:systemd Resolver:/:/usr/sbin/nologin
  25   │ uuidd:x:103:103::/run/uuidd:/usr/sbin/nologin
  26   │ usbmux:x:104:46:usbmux daemon,,,:/var/lib/usbmux:/usr/sbin/nologin
  27   │ tss:x:105:105:TPM software stack,,,:/var/lib/tpm:/bin/false
  28   │ systemd-oom:x:990:990:systemd Userspace OOM Killer:/:/usr/sbin/nologin
  29   │ kernoops:x:106:65534:Kernel Oops Tracking Daemon,,,:/:/usr/sbin/nologin
  30   │ whoopsie:x:107:109::/nonexistent:/bin/false
  31   │ dnsmasq:x:999:65534:dnsmasq:/var/lib/misc:/usr/sbin/nologin
  32   │ avahi:x:108:111:Avahi mDNS daemon,,,:/run/avahi-daemon:/usr/sbin/nologin
  33   │ tcpdump:x:109:112::/nonexistent:/usr/sbin/nologin
  34   │ sssd:x:110:113:SSSD system user,,,:/var/lib/sss:/usr/sbin/nologin
  35   │ speech-dispatcher:x:111:29:Speech Dispatcher,,,:/run/speech-dispatcher:/bin/false
  36   │ cups-pk-helper:x:112:114:user for cups-pk-helper service,,,:/nonexistent:/usr/sbin/nologin
  37   │ fwupd-refresh:x:989:989:Firmware update daemon:/var/lib/fwupd:/usr/sbin/nologin
  38   │ saned:x:113:116::/var/lib/saned:/usr/sbin/nologin
  39   │ geoclue:x:114:117::/var/lib/geoclue:/usr/sbin/nologin
  40   │ cups-browsed:x:115:114::/nonexistent:/usr/sbin/nologin
  41   │ hplip:x:116:7:HPLIP system user,,,:/run/hplip:/bin/false
  42   │ gnome-remote-desktop:x:988:988:GNOME Remote Desktop:/var/lib/gnome-remote-desktop:/usr/sbin/nologin
  43   │ polkitd:x:987:987:User for polkitd:/:/usr/sbin/nologin
  44   │ rtkit:x:117:119:RealtimeKit,,,:/proc:/usr/sbin/nologin
  45   │ colord:x:118:120:colord colour management daemon,,,:/var/lib/colord:/usr/sbin/nologin
  46   │ gnome-initial-setup:x:119:65534::/run/gnome-initial-setup/:/bin/false
  47   │ gdm:x:120:121:Gnome Display Manager:/var/lib/gdm3:/bin/false
  48   │ nm-openvpn:x:121:122:NetworkManager OpenVPN,,,:/var/lib/openvpn/chroot:/usr/sbin/nologin
  49   │ tester:x:1000:1000:tester:/home/tester:/usr/bin/zsh
  50   │ _flatpak:x:122:124:Flatpak system-wide installation helper,,,:/nonexistent:/usr/sbin/nologin
  51   │ sshd:x:123:65534::/run/sshd:/usr/sbin/nologin
  52   │ systemd-coredump:x:983:983:systemd Core Dumper:/:/usr/sbin/nologin
  53   │ deploy:x:997:1001:Deployment automation user:/home/deploy:/usr/sbin/nologin
  54   │ appuser:x:995:1002:Application runtime user:/home/appuser:/usr/sbin/nologin
```

**Each line consists of several fields separated by colons (:). In the example, the fields are:**

```bash
- The username (tester). A unique string with a maximum length of 32 characters.
- x. The encrypted password stored in the /etc/shadow file. 
- UID (1000). The user ID (UID) is a unique number assigned by the operating system to each user.
- GID (1000). The Group ID (GID) refers to the user primary group. The primary group has the same name as the user. Secondary groups are listed in the /etc/groups file.
- GECOS (tester). Represents the User ID Info (GECOS), the comment field that contains additional information about the user.
    For example, the user's full name, phone number, and other contact details.
- The home directory (/home/tester). The absolute path to the directory where users are placed when they log in. It contains the user's files and configurations.
- The default shell (/usr/bin/zsh). The user's default shell that starts when the user logs into the system.
```

---

## Understanding /etc/passwd and /etc/shadow

```bash
# /etc/passwd — user accounts (world-readable, NO passwords)
# Format: username:x:UID:GID:comment:home:shell
cat /etc/passwd | grep tester
# → tester:x:1000:1000:tester:/home/tester:/usr/bin/zsh

# Field breakdown:
# tester    = username
# x         = password hash is in /etc/shadow (not here)
# 1000      = UID (User ID) — 0=root, 1-999=system, 1000+=regular users
# 1000      = GID (primary Group ID)
# tester    = GECOS comment (full name, etc.)
# /home/tester = home directory
# /usr/bin/zsh = login shell

# /etc/shadow — password hashes (root-readable only)
sudo cat /etc/shadow | grep tester
# → tester:$6$salt$hash...:19600:0:99999:7:::

# /etc/group — group definitions
# Format: groupname:x:GID:members
cat /etc/group | grep docker
# → docker:x:984:tester  ← you are in docker group

```

### Creating a Production-Like User Structure

In real DevOps environments, you never run applications as root or as your personal user. Standard pattern:

```bash
deploy   — runs deployments, owns /opt/app, no login shell
appuser  — runs the application process
devops   — group for engineers with controlled sudo access
```

***Let's create this safely on your desktop:***

```bash
# ── Create groups ─────────────────────────────────────────

# Create 'devops' group for engineers
sudo groupadd devops

# Create 'appteam' group for application processes
sudo groupadd appteam

# Verify groups were created
grep -E "devops|appteam" /etc/group

# ── Create system users (no home dir, no login — safe) ────

# 'deploy' user — for deployment scripts
# --system: UID < 1000, no home directory by default
# --no-create-home: explicit safety
# --shell /usr/sbin/nologin: cannot log in interactively
# --gid devops: primary group
sudo useradd \
  --system \
  --no-create-home \
  --shell /usr/sbin/nologin \
  --gid devops \
  --comment "Deployment automation user" \
  deploy

# 'appuser' — for running application processes
sudo useradd \
  --system \
  --no-create-home \
  --shell /usr/sbin/nologin \
  --gid appteam \
  --comment "Application runtime user" \
  appuser

# Verify
id deploy
id appuser
# → uid=XXX(deploy) gid=XXX(devops) groups=XXX(devops)

# ── Add your user 'tester' to the devops group ────────────
sudo usermod --append --groups devops tester
# --append (-a): add to group WITHOUT removing from current groups
# --groups (-G): the group(s) to add
# WARNING: without --append, -G REPLACES all secondary groups

# Verify
groups tester
# → tester : tester adm cdrom sudo ... devops

# You need to log out and back in for group changes to take effect
# OR use newgrp to activate in current session:
newgrp devops
```

&nbsp;

### Creating Production-Like Directory Structure

Now let's create a server-like app structure inside devops-lab/infra/:

```bash
cd ~/Development/learning/devops-lab
git checkout -b day03/feat/permissions-and-users

# Create production-like server directory layout
mkdir -p infra/server-simulation/{app,config,logs,scripts,backup}
mkdir -p infra/server-simulation/config/{nginx,app}
mkdir -p infra/server-simulation/app/{releases,shared,current}

# This mirrors real server layouts:
# /opt/app/releases/   → deployment versions (Capistrano/Deployer pattern)
# /opt/app/current/    → symlink to active release
# /opt/app/shared/     → persistent data: uploads, env files

```

```bash
# Create realistic placeholder files
cat > infra/server-simulation/config/nginx/app.conf << 'EOF'
# Nginx virtual host configuration
# Purpose: Serve the application on port 80 and 443
# Owner: devops team
# Last modified: 2026-03-06

server {
    listen 80;
    server_name app.example.com;

    # Redirect all HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name app.example.com;

    # SSL certificates managed by certbot
    ssl_certificate     /etc/letsencrypt/live/app.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.example.com/privkey.pem;

    root /opt/app/current/public;
    index index.html;

    access_log /var/log/nginx/app_access.log;
    error_log  /var/log/nginx/app_error.log warn;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

cat > infra/server-simulation/config/app/env.example << 'EOF'
# Application environment variables
# IMPORTANT: Copy this to .env and fill in real values.
# NEVER commit .env to git — it contains secrets.

APP_ENV=production
APP_PORT=3000
APP_LOG_LEVEL=info

# Database — fill in real values in .env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=REPLACE_WITH_REAL_PASSWORD

# External services
API_KEY=REPLACE_WITH_REAL_KEY
EOF

# Create placeholder log files (simulate production logs)
touch infra/server-simulation/logs/{app.log,error.log,access.log,deploy.log}

echo "2026-03-06 01:00:00 INFO  Deployment started by deploy@ci-server" \
  >> infra/server-simulation/logs/deploy.log
echo "2026-03-06 01:00:45 INFO  Release v1.2.3 deployed successfully" \
  >> infra/server-simulation/logs/deploy.log
echo "2026-03-06 01:00:45 INFO  Symlink /opt/app/current updated" \
  >> infra/server-simulation/logs/deploy.log

```

**Now apply production-correct permissions to this structure:**

```bash
# Config files — readable by owner and group, not world
chmod 640 infra/server-simulation/config/nginx/app.conf
chmod 640 infra/server-simulation/config/app/env.example

# Log files — writable by owner, readable by group (for log aggregators)
chmod 664 infra/server-simulation/logs/*.log

# Directories — owner full, group read+traverse, others nothing
chmod 750 infra/server-simulation/
chmod 750 infra/server-simulation/config/
chmod 750 infra/server-simulation/logs/

# Scripts must be executable but not world-writable
chmod 750 scripts/day02/fs_audit.sh

# Verify everything
ls -laR infra/server-simulation/
```

---

## sudo - Controlled Privilege Escalation

### How sudo Works (The Full Picture)

```bash
You type: sudo nginx -t
    │
    ▼
sudo checks /etc/sudoers and /etc/sudoers.d/
    │
    ├── Is "tester" allowed to run "nginx" as root?
    │       ├── YES → asks for YOUR password → runs as root
    │       └── NO  → "tester is not in the sudoers file. This incident will be reported."
    │
    ▼
Runs: nginx -t with effective UID=0 (root)
```

---

```bash
# View your current sudo privileges
sudo -l
# Shows: what commands you can run as which users

# On your system (tester has full sudo):
# (ALL : ALL) ALL  ← you can run any command as any user

# Run a single command as root
sudo cat /etc/shadow

# Run a command as a different user (not root)
sudo -u deploy whoami
# → deploy

# Open a root shell (use sparingly, exit immediately when done)
sudo -i     # login shell (loads root's environment)
sudo -s     # non-login shell (keeps your environment)
exit        # always exit root shell immediately when done
```

---

![4f54f58606a4b75585b586294b08989f.png](:/cc31850327074ea59f5896db430f3a35)

---

## Configuring sudoers — Production Pattern

In production, **you never give full sudo**. You give specific commands only:

```bash
# NEVER edit /etc/sudoers directly — use visudo or /etc/sudoers.d/
# visudo validates syntax before saving — a broken sudoers locks you out!

# Create a drop-in file for the devops group
sudo visudo -f /etc/sudoers.d/devops-team

```

&nbsp;

In the editor, write:

```bash
# /etc/sudoers.d/devops-team
# Purpose: Allow devops engineers to manage services without full root
# Security: Principle of least privilege — only what is needed

# Allow devops group to manage systemd services (no password required for CI)
%devops ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx
%devops ALL=(ALL) NOPASSWD: /bin/systemctl restart app
%devops ALL=(ALL) NOPASSWD: /bin/systemctl status *
%devops ALL=(ALL) NOPASSWD: /usr/bin/nginx -t

# Allow deploy user to run deployment scripts only
deploy  ALL=(ALL) NOPASSWD: /opt/app/scripts/deploy.sh

# Syntax breakdown:
# %devops          = group devops (% prefix = group)
# ALL=             = from any host
# (ALL)            = run as any user
# NOPASSWD:        = no password prompt (for CI/CD automation)
# /bin/systemctl   = only this specific command is allowed

```

&nbsp;

```bash
# Verify the file is valid
sudo visudo -c -f /etc/sudoers.d/devops-team
# → /etc/sudoers.d/devops-team: parsed OK

# Test it
sudo -l -U tester

```

---

1. Using **sudo -i** for interactive root login shell: The sudo -i option starts an interactive login shell as the root user, simulating a full root login. This is the most common way to get a root shell environment.
This command starts a login shell for root, reading root’s .profile, .bash_profile, and other initialization files. The working directory changes to root’s home directory (typically /root), and all environment variables are set as if root had logged in directly. This is equivalent to running sudo su - and provides a complete root environment.

2. Using **sudo -s** to preserve your environment: The sudo -s option starts a shell as root but preserves your current user’s environment variables and working directory.
This command runs the shell specified in your SHELL environment variable with root privileges, but keeps your current directory and most environment settings. This is useful when you need root access but want to maintain your current working context. The shell doesn’t read root’s login files, making it faster to start than sudo -i.

3. Running commands as a specific user with sudo -u: The sudo -u option allows you to execute commands as any user on the system, not just root.

```bash
sudo -u postgres psql
````

This command starts an interactive login shell as the postgres user, reading that user’s initialization files and changing to their home directory. This is useful for troubleshooting user-specific issues or managing applications that require a specific user context.

---
**Understanding the difference between sudo su and sudo -i**:
While both commands give you a root shell, there are subtle differences in how they work.

```bash
sudo su -
```

This command uses sudo to run the su command, which then switches to root. The hyphen after su makes it a login shell. While functionally similar to sudo -i, using sudo -i is more direct and efficient because it doesn’t involve starting an additional su process. Therefore, sudo -i is the recommended approach for starting an interactive root shell on modern systems.

---

## 🎤 Interview Prep

**Why This Matters on Interviews**
"Explain Linux file permissions" — this appears in nearly every DevOps/SRE interview. Interviewers expect you to read a permission string instantly, explain the security model, and know how to fix insecure configurations.

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

---

Q: "What does 755 mean in Linux permissions?"

EN: "755 is octal notation. The owner has read, write, and execute. The group and others have read and execute only — no write access. In practice, 755 is the default for directories and public scripts. For sensitive scripts I prefer 750, which removes all access for others."

Q: "What is the principle of least privilege?"

EN: "Every user, process, and service should have only the minimum permissions needed to do its job — nothing more. In practice: applications run as dedicated non-root users, scripts have 750 not 777, service accounts have no login shell. This limits the blast radius if something is compromised."

Q: "What is SUID and why is it a security concern?"

EN: "SUID — Set User ID — means the executable runs as the file owner rather than the calling user. passwd needs it to write /etc/shadow as root. The security concern is that any SUID binary with a vulnerability becomes a privilege escalation path. I regularly audit them with find /usr/bin /usr/sbin -perm -4000 and investigate anything unexpected."

Q: "How do you give a user sudo access to specific commands only?"

EN: "I create a file in /etc/sudoers.d/ using visudo -f — never edit sudoers directly, because a syntax error locks you out. I use the format %groupname ALL=(ALL) NOPASSWD: /specific/command. The NOPASSWD is useful for CI/CD automation. The key principle is restricting to exact binary paths, not using ALL."
