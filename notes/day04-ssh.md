# Day 04 — SSH Architecture and Hardening

# SSH: Architecture, Hardening & Key Management

**SSH (short for Secure Shell)** is a network protocol that provides a secure way for two computers to connect remotely. SSH employs encryption to ensure that hackers cannot interpret the traffic between two connected devices.

* * *

## What is SSH Used for?

SSH provides a layer of security for information transfer between machines. Some important use cases for SSH are:

```bash
- Remote access – SSH ensures encrypted remote connections for users and processes.
- File transfers – SFTP, a secure file transfer protocol managed by SSH, provides a safe way to manipulate files over a network.
- X11 Forwarding – Users can run server-hosted X applications from their client machines.
- Tunneling – This encapsulation technique provides secure data transfers. Tunneling is useful for accessing business-sensitive online materials from unsecured networks, as it can act as a handy VPN alternative.
- Network management – The SSH protocol manages network infrastructure and other parts of the system.
- Port Forwarding – By mapping a client’s port to the server’s remote ports, SSH helps secure other network protocols, such as TCP/IP.
```

* * *

**SSH использует два вида шифрования:**

```bash
1. Asymmetric encryption (асимметричное шифрование)
   — используется ТОЛЬКО при установке соединения
   — у тебя два ключа: публичный (замок) и приватный (ключ)
   — всё что зашифровано публичным ключом — расшифровывается ТОЛЬКО приватным

2. Symmetric encryption (симметричное шифрование)
   — используется для ВСЕХ данных во время сессии
   — один общий секретный ключ генерируется на каждую сессию
   — быстрее асимметричного

```

![113dd26e3d54e35a8f118d852b805f9d.png](:/7b3308e765454406a2f5f7f97473e1a2)

## How Key-Based Auth Works

1. Client sends public key identity to server
2. Server checks authorized_keys for a match
3. Server encrypts a challenge with client public key
4. Client decrypts with private key and proves ownership
5. Private key never leaves the client machine

```bash
КЛИЕНТ (ты)                              СЕРВЕР
    │                                        │
    │──── TCP connection (port 22) ─────────►│
    │                                        │
    │◄─── Server's host key (публичный) ─────│
    │     (ты видишь fingerprint при 1м      │
    │      подключении — это он)             │
    │                                        │
    │    Оба генерируют общий сессионный     │
    │    ключ через алгоритм Diffie-Hellman  │
    │    (математика: никто не передаёт      │
    │    секрет по сети — оба вычисляют      │
    │    одинаковый результат независимо)    │
    │                                        │
    │    ═══ Всё дальше зашифровано ════     │
    │                                        │
    │──── "Я — tester, вот мой публичный ───►│
    │      ключ id_ed25519_github.pub"       │
    │                                        │
    │     Сервер смотрит в                   │
    │     ~/.ssh/authorized_keys:            │
    │     "Есть ли этот ключ в списке?"      │
    │                                        │
    │     Сервер создаёт случайное число,    │
    │     шифрует его ТВОИМ публичным ключом │
    │◄─── "Расшифруй это" ────────────────── │
    │                                        │
    │     Ты расшифровываешь своим           │
    │     ПРИВАТНЫМ ключом                   │
    │──── Отправляешь доказательство ───────►│
    │                                        │
    │◄─── "Добро пожаловать" ─────────────── │
    │                                        │
    │    ═══ Сессия открыта ═══              │

```

**Ключевой вывод:** Твой приватный ключ никогда не покидает твою машину. Сервер доказывает только то, что ты владеешь приватным ключом — не зная его содержимого.

---

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| sshd_config | /etc/ssh/sshd_config | Server daemon config |
| authorized_keys | ~/.ssh/authorized_keys | Permitted public keys |
| ssh_config / config | ~/.ssh/config | Client connection profiles |
| known_hosts | ~/.ssh/known_hosts | Verified server host keys |

---

## Critical sshd Settings

- PasswordAuthentication no
- PermitRootLogin no
- MaxAuthTries 3
- PubkeyAuthentication yes
  
---

**EN (interview-ready explanation):**  
"SSH authentication works in two phases. First, a symmetric session key is negotiated using Diffie-Hellman key exchange — both sides derive the same secret without ever transmitting it over the network. Second, the client authenticates using its private key: the server encrypts a challenge with the client's public key from authorized_keys, the client decrypts it with the private key and proves ownership. The private key never leaves the client machine. This is why key-based auth is fundamentally stronger than passwords — there's nothing to intercept or brute-force on the wire.

&nbsp;

* * *

## The authorized_keys File — How the Server Knows You

```bash
# On any server you want to access:
# ~/.ssh/authorized_keys contains the PUBLIC keys of allowed users

# Format: one public key per line
# algorithm  base64-encoded-key  comment
cat ~/.ssh/id_ed25519_github.pub
# → ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your_email@example.com

# Each line in authorized_keys = one permitted client
# You can add options before the key:
# no-pty,no-port-forwarding ssh-ed25519 AAAA... restricted-key

```

* * *

## 🛠️ Setting Up SSH to Localhost (Safe Production Simulation)

We will configure SSH on your desktop to simulate a production server. This is safe — you already have sshd running.

```bash
# Verify sshd is running
systemctl status sshd
# → Active: active (running)

# Check what port it's on
ss -tlnp | grep sshd
# → LISTEN 0 4096 0.0.0.0:22 ...

```

* * *

Create a Dedicated Key for Localhost (Server Simulation)

```bash
# Generate a separate key for local server connections
# Keep keys separated by purpose — good practice
ssh-keygen \
  -t ed25519 \
  -C "tester@localhost-devops-lab" \
  -f ~/.ssh/id_ed25519_local \
  -N ""
# -N "": empty passphrase for lab purposes
# In production: always set a passphrase on keys

# Authorize this key for localhost connection
# authorized_keys must be in the TARGET user's home
mkdir -p ~/.ssh
cat ~/.ssh/id_ed25519_local.pub >> ~/.ssh/authorized_keys

# Set mandatory permissions — SSH is strict about this
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519_local
chmod 644 ~/.ssh/id_ed25519_local.pub

# Verify
ls -la ~/.ssh/

```

* * *

Create SSH Client Config (~/.ssh/config)

```bash
cat > ~/.ssh/config << 'EOF'
# ~/.ssh/config
# Purpose: Define named SSH connection profiles.
# This avoids typing long flags every time.
# Permissions must be 600 — SSH ignores this file if too open.

# ── GitHub ────────────────────────────────────────────────
Host github
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    AddKeysToAgent yes
    # AddKeysToAgent: automatically adds key to ssh-agent on first use

# ── Local server simulation ───────────────────────────────
Host localhost-lab
    HostName 127.0.0.1
    Port 22
    User tester
    IdentityFile ~/.ssh/id_ed25519_local
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    # ServerAliveInterval: send keepalive every 60 seconds
    # ServerAliveCountMax: disconnect after 3 missed keepalives
    # These prevent "broken pipe" errors on idle connections

# ── Future AWS server (template — not active yet) ─────────
# Host aws-prod
#     HostName REPLACE_WITH_IP
#     Port 22
#     User ubuntu
#     IdentityFile ~/.ssh/id_ed25519_aws
#     ServerAliveInterval 60
#     ServerAliveCountMax 3

# ── Default settings for all connections ─────────────────
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    # IdentitiesOnly yes: only use keys explicitly configured
    # Prevents ssh from trying ALL keys in agent (security + speed)
EOF

chmod 600 ~/.ssh/config

```

* * *

Test the config:

```bash
# Test GitHub (from Day 1)
ssh github
# → Hi tester! You've successfully authenticated...

# Test localhost with named profile
ssh localhost-lab
# → Should connect without password, no flags needed
# Type 'exit' to close the session

# If connection is refused, check sshd is running:
sudo systemctl start sshd

```

* * *

## 🛠️ Hardening sshd_config

Что такое **sshd_config** — объяснение на русском  
**sshd (SSH Daemon)** — это серверная часть SSH, которая постоянно работает в фоне и ждёт входящих подключений. Файл /etc/ssh/sshd_config — это его конфигурация.  
Важно понять разницу:

```bash
ssh        → клиентская программа (ты подключаешься К серверу)
             Конфиг: ~/.ssh/config

sshd       → серверная программа (к тебе подключаются)
             Конфиг: /etc/ssh/sshd_config

Ты редактируешь sshd_config чтобы контролировать:
— кто может подключаться
— какими методами
— с каких IP-адресов
— с какими ключами

```

==Почему это критично==: дефолтный sshd_config на Ubuntu небезопасен для production. Он разрешает подбор паролей (brute-force), допускает root-логин, использует устаревшие алгоритмы.

Reading the Current Configuration

```bash
# View active (non-comment) lines only
sudo grep -v "^#" /etc/ssh/sshd_config | grep -v "^$"

# Check specific settings
sudo sshd -T | grep -E "passwordauth|permitroot|pubkeyauth|port"
# sshd -T: dump the full effective configuration (compiled defaults + file)
# This shows what sshd is ACTUALLY using, not just what's in the file

```

### Create a Hardened Drop-In Configuration

We use **/etc/ssh/sshd_config.d/** — the drop-in directory — instead of editing the main file. Same principle as **sudoers.d**.

```bash
# First, create a backup of current config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Create the hardening drop-in file
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# /etc/ssh/sshd_config.d/99-hardening.conf
# Purpose: Production SSH hardening rules.
# Applied on top of /etc/ssh/sshd_config.
# File 99- prefix ensures this loads last and overrides defaults.

# ── Authentication ─────────────────────────────────────────

# Disable password authentication entirely.
# Key-based auth only — eliminates brute-force attack surface.
PasswordAuthentication no

# Disable empty passwords.
PermitEmptyPasswords no

# Disable root login.
# Reason: root has no audit trail — you can't tell who used it.
# Use sudo from a regular user instead.
PermitRootLogin no

# Enable public key authentication (explicitly — don't rely on default).
PubkeyAuthentication yes

# Disable challenge-response auth (includes PAM passwords).
KbdInteractiveAuthentication no

# ── Connection Settings ─────────────────────────────────────

# Maximum authentication attempts per connection.
# Low value limits brute-force window.
MaxAuthTries 3

# Maximum concurrent unauthenticated connections.
# Format: start:rate:full
# 10:30:60 = allow 10 unauth connections, then 30% drop rate, hard limit 60
MaxStartups 10:30:60

# Disconnect idle sessions after 5 minutes.
# ClientAliveInterval: send keepalive every 60 seconds.
# ClientAliveCountMax: disconnect after 5 missed responses.
ClientAliveInterval 60
ClientAliveCountMax 5

# ── Algorithms (Cryptographic Hardening) ───────────────────
# Only allow modern, secure algorithms.
# Removes weak legacy algorithms (DSA, old CBC ciphers, MD5/SHA1 MACs).

# Key Exchange algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Symmetric encryption ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# Message Authentication Codes
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com

# ── Logging ────────────────────────────────────────────────

# Log authentication events.
# VERBOSE: logs key fingerprint used — useful for audit trails.
LogLevel VERBOSE

# ── Misc Security ──────────────────────────────────────────

# Disable X11 forwarding (GUI forwarding — not needed on servers).
X11Forwarding no

# Disable TCP forwarding unless explicitly needed.
# AllowTcpForwarding no   # Uncomment on hardened servers
EOF

```

---

**Test and Apply**

```bash
# CRITICAL: always test before reloading
# sshd -t: test configuration syntax
sudo sshd -t
# → If no output: config is valid
# → If error shown: fix it before reloading

# Reload sshd — applies new config without dropping existing sessions
# Use reload, NOT restart (restart drops all active connections)
sudo systemctl reload sshd

# Verify the new settings are active
sudo sshd -T | grep -E "passwordauthentication|permitrootlogin|maxauthtries|loglevel"
# → passwordauthentication no
# → permitrootlogin no
# → maxauthtries 3
# → loglevel VERBOSE

# Test that key auth still works
ssh localhost-lab
# → should connect successfully with key

# Verify password auth is rejected
# (safe test — wrong method, not brute force)
ssh -o PasswordAuthentication=yes -o PubkeyAuthentication=no localhost-lab
# → Permission denied (publickey)
# This is the correct, expected response

```

----

## SSH Tunneling & Port Forwarding

```bash
Ситуация: есть база данных на сервере, она слушает только localhost:5432
           Снаружи к ней нельзя подключиться напрямую.
           Но у тебя есть SSH-доступ к этому серверу.

БЕЗ туннеля:             С туннелем (Local Port Forwarding):

Твой ноутбук             Твой ноутбук
     │                        │
     │ ❌ нельзя              │ ssh -L 5555:localhost:5432 server
     │ подключиться           │
     ▼                        ▼
   Internet              ╔══════════════╗ SSH туннель (зашифровано)
     │                   ║    Internet  ║──────────────────────────►
     ▼                   ╚══════════════╝
   Сервер                     │
  (DB только                  ▼
   localhost:5432)           Сервер
                           ┌─────────────┐
                           │ DB: 5432    │ ← только localhost
                           └─────────────┘

Результат: ты подключаешься к localhost:5555 на своём ноутбуке,
           SSH прозрачно перенаправляет это в localhost:5432 на сервере.

```

**Три типа port forwarding:**

| Тип          | Команда                                   | Что делает                       |
| ------------ | ----------------------------------------- | -------------------------------- |
| Local (-L)   | ssh -L local_port:target:target_port host | Твой порт → порт на сервере      |
| Remote (-R)  | ssh -R remote_port:local:local_port host  | Порт на сервере → твой локальный |
| Dynamic (-D) | ssh -D local_port host                    | SOCKS5 прокси через сервер       |

---
**EN (interview-ready):**
"SSH local port forwarding creates an encrypted tunnel between a local port on my machine and a port on the remote server's network.
The classic use case: a database that listens only on localhost on the server. I run ssh -L 5555:localhost:5432 server, then connect my local DB client to localhost:5555 — traffic goes through the SSH tunnel and arrives at the database. Nobody can intercept it. Remote forwarding is the reverse — expose a local service through the server.
Dynamic forwarding creates a SOCKS5 proxy, useful for routing all traffic through the server."

---

```bash
# Practice — safe local test using localhost-lab

# Local port forwarding example:
# Forward local port 8080 → port 22 on the server (meta-tunnel for demo)
ssh -L 8080:localhost:22 localhost-lab -N -f
# -N: don't execute a command (just forward)
# -f: go to background

# Verify the tunnel is open
ss -tlnp | grep 8080
# → LISTEN on 127.0.0.1:8080

# Connect through the tunnel
ssh -p 8080 tester@localhost
# → You're now SSH'd into localhost through the tunnel

# Clean up
pkill -f "ssh -L 8080"
```

---

## 🎤 Interview Prep — Day 4

**Q: "How does SSH key authentication work?"**

EN: "The client proves it owns the private key without revealing it. The server sends a challenge encrypted with the client's public key from authorized_keys. Only the holder of the matching private key can decrypt and respond correctly. The private key never travels over the network — unlike a password."

**Q: "How would you harden an SSH server?"**

EN: "I start with three non-negotiables: disable password authentication, disable root login, and set MaxAuthTries to 3. Then I restrict algorithms to modern ones — Ed25519 keys, ChaCha20 ciphers, ETM MACs. I enable verbose logging for audit trails. I use the drop-in directory /etc/ssh/sshd_config.d/ so the changes are isolated and traceable. I always test with sshd -t before reloading, and I verify with sshd -T after — not by reading the config file, because there may be compiled-in defaults that override it."

**Q: "What is SSH port forwarding and when would you use it?"**

EN: "Local port forwarding lets me access a service on a remote network that isn't publicly exposed. Classic example: a database that listens only on localhost on the server. I run ssh -L 5432:localhost:5432 server and connect my local DB client to port 5432 — traffic tunnels through SSH encrypted. I use this for database access, internal web UIs, and anything behind a firewall. It's also useful for testing production services from my local machine without exposing them publicly."

## Bug DVPS-16 — Fix

Symptom: PasswordAuthentication was set to yes (default)
Fix: Created /etc/ssh/sshd_config.d/99-hardening.conf
     Set PasswordAuthentication no
     Reloaded: sudo systemctl reload sshd
Verified: ssh -o PasswordAuthentication=yes localhost-lab → Permission denied
