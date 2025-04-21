#!/bin/bash

INPUT_FILE="servers.csv"
DEFAULT_PARALLEL_JOBS=5
TMP_JOBLOG="ipmi_parallel.log"
TMP_NEW_IPS="ipmi_new_ips.txt"
LOGDIR="./logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$LOGDIR/ipmi-run-$TIMESTAMP.log"

mkdir -p "$LOGDIR"
rm -f "$TMP_JOBLOG" "$TMP_NEW_IPS"

log() {
    echo -e "[$(date +'%F %T')] $*" | tee -a "$LOGFILE"
}

retry() {
    local cmd="$1"
    local desc="$2"
    local attempt=1
    local max=3

    while [[ $attempt -le $max ]]; do
        eval "$cmd" && return 0
        log "[!] Attempt $attempt failed for $desc"
        ((attempt++))
        sleep 5
    done

    log "[✗] All attempts failed for $desc"
    return 1
}

change_ipmi_ip() {
    IFS=',' read -r ip user pass new_ip <<< "$1"
    log "[*] Connecting to $ip as $user to change IP to $new_ip..."

    if ! retry "ipmitool -I lanplus -H \"$ip\" -U \"$user\" -P \"$pass\" lan print > /dev/null 2>&1" "IPMI access to $ip"; then
        return
    fi

    vendor=$(ipmitool -I lanplus -H "$ip" -U "$user" -P "$pass" fru 2>/dev/null | grep -i "manufacturer" | awk -F: '{print $2}' | xargs)
    vendor=${vendor:-"Unknown"}
    log "[*] Detected Vendor: $vendor"

    retry "ipmitool -I lanplus -H \"$ip\" -U \"$user\" -P \"$pass\" lan set 1 ipsrc static" "set static IP mode on $ip"
    retry "ipmitool -I lanplus -H \"$ip\" -U \"$user\" -P \"$pass\" lan set 1 ipaddr \"$new_ip\"" "set new IP on $ip"

    log "[*] Verifying IP address update on $ip..."
    updated_ip=$(ipmitool -I lanplus -H "$ip" -U "$user" -P "$pass" lan print 2>/dev/null | grep -i "IP Address" | head -n 1 | awk -F: '{print $2}' | xargs)

    if [[ "$updated_ip" == "$new_ip" ]]; then
        log "[+] IP confirmed as $new_ip"
    else
        log "[✗] Failed to confirm new IP for $ip. Found: '$updated_ip'"
        return
    fi

    echo "$new_ip" >> "$TMP_NEW_IPS"

    log "[*] Rebooting BMC on $ip..."
    retry "ipmitool -I lanplus -H \"$ip\" -U \"$user\" -P \"$pass\" mc reset cold" "BMC reset on $ip"
    log "[*] BMC reboot initiated on $ip -> $new_ip"
}

export -f change_ipmi_ip
export -f retry
export -f log
export TMP_NEW_IPS LOGFILE

read -p "Run in parallel? [y/N]: " run_parallel
run_parallel=${run_parallel,,}

if [[ "$run_parallel" == "y" ]]; then
    read -p "How many parallel jobs? (default: $DEFAULT_PARALLEL_JOBS): " jobs
    jobs=${jobs:-$DEFAULT_PARALLEL_JOBS}
    log "[*] Launching jobs in parallel..."
    grep -v '^#' "$INPUT_FILE" | grep -E '^.+' | \
        parallel --joblog "$TMP_JOBLOG" -j "$jobs" change_ipmi_ip
    log "[*] All jobs completed. Summary:"
    tail -n +2 "$TMP_JOBLOG" | awk '{print $1 " - Exit: " $7}' | tee -a "$LOGFILE"
else
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        change_ipmi_ip "$line"
    done < "$INPUT_FILE"
fi

read -p "Do you want to ping all new IPs to verify? [y/N]: " ping_all
ping_all=${ping_all,,}

if [[ "$ping_all" == "y" ]]; then
    log "[*] Pinging all updated IPMI IPs:"
    sort -u "$TMP_NEW_IPS" | while read -r ip; do
        if ping -c 1 -W 2 "$ip" > /dev/null; then
            log "[✓] $ip is online"
        else
            log "[✗] $ip did not respond"
        fi
    done
else
    log "[*] Skipped final ping sweep."
fi

read -p "Do you want to verify IPMI access on the new IPs via ipmitool? [y/N]: " check_ipmi
check_ipmi=${check_ipmi,,}

if [[ "$check_ipmi" == "y" ]]; then
    log "[*] Verifying IPMI login on new IPs..."
    while IFS=',' read -r old_ip user pass new_ip; do
        [[ "$old_ip" =~ ^#.*$ || -z "$old_ip" ]] && continue
        log "[*] Checking IPMI at $new_ip..."
        if ipmitool -I lanplus -H "$new_ip" -U "$user" -P "$pass" lan print > /dev/null 2>&1; then
            log "[✓] Connected to $new_ip successfully with $user"
        else
            log "[✗] Failed to connect to $new_ip using $user"
        fi
    done < "$INPUT_FILE"
else
    log "[*] Skipped IPMI verification check."
fi
