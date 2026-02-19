# IT 360 Final Project

# Team members:
* Logan
* Hunter
* Brett

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
