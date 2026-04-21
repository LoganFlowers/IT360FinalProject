#!/bin/bash

# =========================
# Linux Incident Response Evidence Collector
# =========================

set -e

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
HOSTNAME=$(hostname)
OUTPUT_DIR="IR_Evidence_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/collection.log"
HASH_FILE="${OUTPUT_DIR}/hashes.sha256"

# AI Config
API_URL="http://sushi.it.ilstu.edu:8080/api/chat/completions"
API_KEY="PASTE KEY HERE"
MODEL="translategemma:latest"

# =========================
# Logging
# =========================
log() {
    echo "[$(date +"%F %T")] $1" | tee -a "$LOG_FILE"
}

# =========================
# Init
# =========================
init() {
    mkdir -p "$OUTPUT_DIR"
    touch "$LOG_FILE"
    log "Initialized evidence collection"
}

# =========================
# System Info
# =========================
collect_system_info() {
    log "Collecting system information..."

    {
        uname -a
        cat /etc/os-release 2>/dev/null || true
        uptime
        lscpu 2>/dev/null || true
        free -h || true
        df -h || true
    } > "${OUTPUT_DIR}/system_info.txt"
}

# =========================
# Processes
# =========================
collect_processes() {
    log "Collecting processes..."
    ps aux > "${OUTPUT_DIR}/processes.txt"
}

# =========================
# Open Files
# =========================
collect_open_files() {
    log "Collecting open files..."
    lsof > "${OUTPUT_DIR}/open_files.txt" 2>/dev/null || echo "lsof not available" >> "${OUTPUT_DIR}/open_files.txt"
}

# =========================
# Network
# =========================
collect_network() {
    log "Collecting network connections..."

    {
        echo "===== SS ====="
        ss -tulnp -n || echo "ss failed"

        echo
        echo "===== ROUTES ====="
        ip route || true

        echo
        echo "===== ARP ====="
        ip neigh || true
    } > "${OUTPUT_DIR}/network.txt"
}

# =========================
# Logs
# =========================
collect_logs() {
    log "Collecting logs..."
    mkdir -p "${OUTPUT_DIR}/logs"

    cp -r /var/log/* "${OUTPUT_DIR}/logs/" 2>/dev/null || true
    journalctl --no-pager > "${OUTPUT_DIR}/logs/journalctl.txt" 2>/dev/null || true
}

# =========================
# Hashing
# =========================
hash_artifacts() {
    log "Hashing artifacts..."
    find "$OUTPUT_DIR" -type f ! -name "hashes.sha256" -exec sha256sum {} \; > "$HASH_FILE"
}

# =========================
# Summary + AI
# =========================
generate_summary() {
    log "Generating summary..."

    SUMMARY_FILE="${OUTPUT_DIR}/summary.txt"
    AI_SUMMARY_FILE="${OUTPUT_DIR}/ai_summary.txt"

    {
        echo "===== INCIDENT RESPONSE SUMMARY ====="
        echo "Hostname: $HOSTNAME"
        echo "Timestamp: $TIMESTAMP"
        echo

        echo "Top Processes by CPU:"
        ps aux --sort=-%cpu | head -n 10

        echo
        echo "Active Network Connections:"
        ss -tunap -n | head -n 20

        echo
        echo "Recent Logs:"
        tail -n 20 /var/log/syslog 2>/dev/null || echo "syslog not available"
    } > "$SUMMARY_FILE"

    # =========================
    # SANITIZE + LIMIT INPUT
    # =========================
    CLEAN_SUMMARY=$(sed 's#/proc/[a-zA-Z0-9_/.-]*#[REDACTED_PROC_PATH]#g' "$SUMMARY_FILE" | head -c 8000)

    echo "$CLEAN_SUMMARY" > "${OUTPUT_DIR}/debug_sent_to_ai.txt"

    # =========================
    # AI CALL
    # =========================
    if command -v curl &>/dev/null && command -v jq &>/dev/null; then
        log "Sending sanitized summary to AI..."

        PAYLOAD=$(jq -n \
            --arg model "$MODEL" \
            --arg content "$CLEAN_SUMMARY" \
            '{
                model: $model,
                messages: [
                    {
                        role: "user",
                        content: ("You are a cybersecurity analyst. Analyze this incident response data.\n\nIdentify:\n- Suspicious processes\n- Network anomalies\n- Indicators of compromise\n- Severity level\n\nData:\n\n" + $content)
                    }
                ]
            }')

        RESPONSE=$(curl -s -X POST "$API_URL" \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD")

        echo "$RESPONSE" > "${OUTPUT_DIR}/api_raw.json"

        echo "$RESPONSE" | jq -r '.choices[0].message.content // "AI summary failed"' > "$AI_SUMMARY_FILE"

        log "AI summary saved"
    else
        log "curl/jq missing — skipping AI"
    fi
}

# =========================
# Compress + Encrypt
# =========================
compress_encrypt() {
    log "Compressing..."

    tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"

    read -s -p "Enter encryption password: " ENC_PASS
    echo

    openssl enc -aes-256-cbc -salt -in "${OUTPUT_DIR}.tar.gz" \
        -out "${OUTPUT_DIR}.tar.gz.enc" -k "$ENC_PASS"

    rm "${OUTPUT_DIR}.tar.gz"

    log "Encrypted archive created"
}

# =========================
# Main
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

    log "Collection complete"
}

main
