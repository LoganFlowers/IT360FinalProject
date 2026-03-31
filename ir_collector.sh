#!/bin/bash

# =========================
# Linux Incident Response Evidence Collector
# =========================

# Exit on error
set -e

# Global variables
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)
OUTPUT_DIR="IR_Evidence_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/collection.log"
HASH_FILE="${OUTPUT_DIR}/hashes.sha256"
ARCHIVE_NAME="${OUTPUT_DIR}.tar.gz.enc"

# Encryption password prompt
read -s -p "Enter encryption password: " ENC_PASS
echo

# =========================
# Logging Function
# =========================
log() {
    echo "[$(date +"%F %T")] $1" | tee -a "$LOG_FILE"
}

# =========================
# Initialize Environment
# =========================
init() {
    mkdir -p "$OUTPUT_DIR"
    touch "$LOG_FILE"
    log "Initialized evidence collection at $TIMESTAMP"
}

# =========================
# Collect System Info
# =========================
collect_system_info() {
    log "Collecting system information..."
    {
        echo "===== SYSTEM INFO ====="
        uname -a
        echo
        echo "===== OS RELEASE ====="
        cat /etc/os-release 2>/dev/null
        echo
        echo "===== UPTIME ====="
        uptime
        echo
        echo "===== CPU INFO ====="
        lscpu 2>/dev/null
        echo
        echo "===== MEMORY ====="
        free -h
        echo
        echo "===== DISK ====="
        df -h
    } > "${OUTPUT_DIR}/system_info.txt"
}

# =========================
# Collect Processes
# =========================
collect_processes() {
    log "Collecting running processes..."
    ps aux > "${OUTPUT_DIR}/processes.txt"
}

# =========================
# Collect Open Files
# =========================
collect_open_files() {
    log "Collecting open files..."
    lsof > "${OUTPUT_DIR}/open_files.txt" 2>/dev/null || echo "lsof not available" >> "${OUTPUT_DIR}/open_files.txt"
}

# =========================
# Collect Network Info
# =========================
collect_network() {
    log "Collecting network connections..."
    {
        echo "===== NETSTAT ====="
        netstat -tulnp 2>/dev/null
        echo
        echo "===== SS ====="
        ss -tulnp
        echo
        echo "===== ROUTES ====="
        ip route
        echo
        echo "===== ARP ====="
        ip neigh
    } > "${OUTPUT_DIR}/network.txt"
}

# =========================
# Collect Logs
# =========================
collect_logs() {
    log "Collecting logs..."
    mkdir -p "${OUTPUT_DIR}/logs"

    cp -r /var/log/* "${OUTPUT_DIR}/logs/" 2>/dev/null || log "Could not copy all /var/log files"

    journalctl --no-pager > "${OUTPUT_DIR}/logs/journalctl.txt" 2>/dev/null || log "journalctl unavailable"
}

# =========================
# Hash Artifacts (SHA-256)
# =========================
hash_artifacts() {
    log "Hashing collected artifacts..."
    find "$OUTPUT_DIR" -type f ! -name "hashes.sha256" -exec sha256sum {} \; > "$HASH_FILE"
}

# =========================
# Generate Summary Report
# =========================
generate_summary() {
    log "Generating summary report..."

    SUMMARY_FILE="${OUTPUT_DIR}/summary.txt"

    {
        echo "===== INCIDENT RESPONSE SUMMARY ====="
        echo "Hostname: $HOSTNAME"
        echo "Timestamp: $TIMESTAMP"
        echo

        echo "Top 10 Processes by CPU:"
        ps aux --sort=-%cpu | head -n 11
        echo

        echo "Top 10 Processes by Memory:"
        ps aux --sort=-%mem | head -n 11
        echo

        echo "Active Network Connections:"
        ss -tunap | head -n 20
        echo

        echo "Recent Log Entries:"
        tail -n 20 /var/log/syslog 2>/dev/null || echo "syslog not available"
    } > "$SUMMARY_FILE"

    # Optional AI hook (placeholder)
    if command -v python3 &>/dev/null; then
        log "AI summary placeholder (extend with API integration)"
    fi
}

# =========================
# Compress + Encrypt
# =========================
compress_encrypt() {
    log "Compressing evidence..."
    tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"

    log "Encrypting archive..."
    openssl enc -aes-256-cbc -salt -in "${OUTPUT_DIR}.tar.gz" -out "$ARCHIVE_NAME" -k "$ENC_PASS"

    rm "${OUTPUT_DIR}.tar.gz"
}

# =========================
# Main Execution
# =========================
main() {
    init
    collect_system_info
    collect_processes
    collect_open_files
    collect_network
    collect_logs
    hash_artifacts
    generate_summary
    compress_encrypt

    log "Collection complete. Encrypted archive: $ARCHIVE_NAME"
}

main
