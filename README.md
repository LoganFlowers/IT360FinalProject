# IT 360 Final Project

# Team members:
* Logan
* Hunter
* Brett

# * NOTE - All programming was performed via paired programming on one machine, hence the uneven distribution of commits.

# Project idea:
## Linux Incident Response Evidence Collector (Bash) 

### What it does 
A Bash script that: 
* Collects system info (OS, kernel, uptime, hardware) 
* Captures running processes, open files, and network connections 
* Gathers logs (/var/log, journalctl) 
* Hashes all collected artifacts 
* Compresses + encrypts the evidence folder 
* Generates a summary report 
### Key forensic principles 
* Data integrity via SHA-256 hashes 
* Chain of custody via timestamps + logging 
* Repeatability via modular functions 
### Stretch ideas if time allows 
* “Minimal footprint” mode (no disk writes until final archive) 
* JSON output for SIEM import 
* Live vs dead system comparison mode
### AI Utilization
* We plan to use AI to generate the summary report
* This will ensure that the report is easily readable and will quickly allow all information to be summarized efficiently

-----------------------------------------
### Setup and Usage
## Setup
1. Clone the Repository
git clone https://github.com/LoganFlowers/IT360FinalProject.git
cd ir-evidence-collector
2. Install System Dependencies (Ubuntu/Debian)  
sudo apt update  
sudo apt install -y \
    lsof \
    net-tools \
    iproute2 \
    procps \
    util-linux \
    curl \
    jq \
    openssl

Note: Some tools such as lsof and netstat are optional but recommended for full forensic visibility.

3. Configure AI API Key

Create an account at http://sushi.it.ilstu.edu:8080/ and generate an API key

Open the script:

nano ir_collector.sh

Locate the following line:

API_KEY="PASTE KEY HERE"

Replace it with your actual API key:

API_KEY="your_real_api_key"

4. Make Script Executable
chmod +x ir_collector.sh

5. Optional Dependency Check
which curl jq ss ip openssl
#Usage

Run the script with root privileges:

sudo ./ir_collector.sh

You will be prompted to enter an encryption password for the final evidence archive.

## Output

The script creates a directory in the following format:

IR_Evidence_<hostname>_<timestamp>/
## Contents
* system_info.txt – system and hardware information
* processes.txt – running processes
* open_files.txt – open file handles
* network.txt – network connections and routing data
* logs/ – system and journal logs
* summary.txt – generated incident summary
* ai_summary.txt – AI-generated analysis
* hashes.sha256 – file integrity hashes
* api_raw.json – raw AI API response (debugging)
* debug_sent_to_ai.txt – sanitized AI input
  
## Final Archive
IR_Evidence_<hostname>_<timestamp>.tar.gz.enc
Verification

## View AI-generated output:

cat IR_Evidence_*/ai_summary.txt

## View raw API response:

cat IR_Evidence_*/api_raw.json

## View sanitized input sent to AI:

cat IR_Evidence_*/debug_sent_to_ai.txt
## Notes  
* The script must be run as root to collect full system data 
* AI functionality requires curl and jq
* System data is sent to an external AI endpoint for analysis; use only in trusted environments
-----------------------------------------
### Video Presentation Link
* https://youtu.be/sgN3TRF8eh0
