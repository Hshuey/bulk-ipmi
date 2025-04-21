

---

```Discription
# Bulk IPMI IP Address Changer

This script performs **bulk IPMI IP address changes** across a list of servers (Supermicro, Dell iDRAC, etc.) using `ipmitool`. It supports both sequential and parallel execution, includes built-in retry logic, verifies IP changes before rebooting the BMC, and generates timestamped logs for traceability.

---

## 📄 Features

- ✅ Supermicro + Dell iDRAC compatibility
- ✅ Supports static IP configuration
- ✅ Confirms IP change via IPMI before rebooting
- ✅ Reboots BMC to apply changes
- ✅ Optional **parallel execution**
- ✅ **Retry logic** for network/IPMI errors (3 attempts)
- ✅ Final verification via:
  - `ping` sweep (optional)
  - IPMI login test (optional)
- ✅ Logs all output to timestamped log files under `./logs`

---

## 🧾 CSV Format (`servers.csv`)

```csv
ip,user,password,new_ip
192.168.1.10,admin,P@ssword!,192.168.100.10
192.168.1.11,root,changeme,192.168.100.11
# Lines starting with '#' are ignored
```

Each line defines:

- `ip`: Current IPMI IP address
- `user`: IPMI login username
- `password`: IPMI password (supports special characters)
- `new_ip`: Desired new IPMI IP address

---

## 🚀 Usage

1. Install dependencies:

    ```bash
    sudo apt install ipmitool parallel
    ```

2. Make the script executable:

    ```bash
    chmod +x bulk-ipmi-change.sh
    ```

3. Run the script:

    ```bash
    ./bulk-ipmi-change.sh
    ```

You will be prompted to:

- Choose **parallel or sequential** execution
- Set **number of parallel jobs** (default: 5)
- Optionally run a **ping sweep** to verify new IPs
- Optionally perform **IPMI login checks** on new IPs

---

## 📁 Logs

All output is logged to a timestamped file:

```
logs/ipmi-run-YYYYMMDD_HHMMSS.log
```

If the `logs/` directory doesn't exist, it will be created automatically.

---

## 📌 Notes

- Passwords are not masked in logs (for transparency during auditing). Use caution if sharing logs.
- This script sets the IP source to `static`. It does not modify subnet/gateway.
- Requires network access to each BMC via IPMI (`lanplus` interface).

---

## 🔐 Security Disclaimer

This tool directly interacts with IPMI interfaces and reboots BMCs. Only use it in **trusted environments** with **authorized credentials**. Do not run this from untrusted networks or expose the input file externally.

---

## 🛠️ TODO / Possible Enhancements

- CSV output summary of success/fail per device
- Password masking in logs
- Integration with DNS updates
- Web dashboard or TUI mode

---
