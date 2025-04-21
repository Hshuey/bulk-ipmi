```markdown
# Bulk IPMI IP Address Changer

A powerful Bash script for performing **bulk IPMI IP address, subnet, and gateway changes** across Supermicro, Dell iDRAC, or any BMC supporting IPMI over LAN. This tool handles configuration, rebooting, logging, and validation — all in one shot.

---

## 📦 Features

- ✅ Supermicro + Dell compatibility
- ✅ Bulk updates: IP address, subnet mask, and default gateway
- ✅ Verifies changes before rebooting BMC
- ✅ Reboots BMC via `mc reset cold`
- ✅ Optional **parallel execution**
- ✅ Built-in **retry logic** (3 attempts per command)
- ✅ `--file` flag to specify custom CSV input
- ✅ `--dry-run` mode to simulate without applying changes
- ✅ Timestamped logs in `./logs/`
- ✅ Success/Fail summary at the end of each run

---

## 📄 Input Format: `servers.csv`

```csv
ip,user,password,new_ip,subnet,gateway
192.168.1.10,admin,P@ssword!,192.168.100.10,255.255.255.0,192.168.100.1
192.168.1.11,root,changeme,192.168.100.11,255.255.255.0,192.168.100.1
# Lines starting with # are ignored
```

Each column:

| Field       | Description                          |
|-------------|--------------------------------------|
| `ip`        | Current IPMI IP address              |
| `user`      | IPMI login username                  |
| `password`  | IPMI password                        |
| `new_ip`    | Desired new IPMI address             |
| `subnet`    | Subnet mask to apply                 |
| `gateway`   | Default gateway IP for BMC interface |

---

## 🚀 Usage

### Basic run:

```bash
./bulk-ipmi-change.sh
```

### With custom input file:

```bash
./bulk-ipmi-change.sh --file custom_input.csv
```

### Dry run (simulate actions without changing anything):

```bash
./bulk-ipmi-change.sh --dry-run
```

You’ll be prompted during execution to:

- Enable or skip parallel job execution
- Ping all new IPs to confirm online status
- Re-check IPMI login over the new IPs

---

## 📁 Logging

- Logs are saved to `logs/ipmi-run-YYYYMMDD_HHMMSS.log`
- Summary includes `Success`, `Fail`, or `Dry-Run` per device

Example:
```
==== Summary ====
192.168.1.10,Success
192.168.1.11,Fail
```

---

## ⚠️ Requirements

Make sure the following tools are installed:

```bash
sudo apt install ipmitool parallel
```

Make the script executable:

```bash
chmod +x bulk-ipmi-change.sh
```

---

## 🔐 Security Note

- Credentials and configuration are processed locally.
- Passwords are shown in logs for auditing — handle log files with care.
- Ensure access is restricted to trusted operators.

---

## 🛠️ TODO / Planned Improvements

- Password masking in output logs
- Optional DNS updates
- JSON/CSV export of final results
- Web UI or TUI view for task monitoring
- Email/Slack alerts on job completion

---

