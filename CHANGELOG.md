# Changelog — Week 3 Network Segmentation & Firewall Policy Review

All times are from 30 Sep 2026 (host laptop clock).

## Setup
- Chose the host laptop as the "server" instead of a separate Windows VM (no download needed, less RAM).
- Reset forgotten Kali password through GRUB (`init=/bin/bash`, `passwd kali`).
- Added a second VirtualBox adapter (Host-only) to Kali. Kali eth1 = 192.168.56.101, host = 192.168.56.1.

## Baseline
- Ping from Kali: 174 sent, 0 received — ICMP blocked by default.
- Enabled three audit subcategories with `auditpol` (logging was off).
- First nmap attempt failed: typed `-pn` instead of `-Pn` (case matters). Corrected.
- `nmap -Pn 192.168.56.1`: all 1000 TCP ports filtered.

## Service
- Python not installed, so built the Billing Portal with PowerShell HttpListener on TCP 8080.
- **Bug:** portal log printed an empty client IP. **Cause:** IP read after `Response.Close()`. **Fix:** read `RemoteEndPoint` first (v2).

## Policy (09:01 – 09:04)
- Created FF-ALLOW Finance, FF-ALLOW IT, FF-BLOCK Guest, FF-BLOCK Warehouse. Office left to default deny.

## Testing (~09:34)
- Added zone IPs to Kali (.45, .15, .35, .55). First attempt typed `apt` instead of `ip`; corrected.
- 5 / 5 zone tests passed. Portal log showed only .45 and .15.
- Event Viewer filter by event ID alone returned host noise (Chrome traffic). Rewrote as XPath filters by IP and port.
- First 5152 match was from the earlier nmap scan (07:55); refined filter and picked the post-rule event (09:34:15).

## Tampering simulation
- 10:49:09 — disabled FF-BLOCK Guest Zone (4947)
- 10:49:44 — added rogue "Windows Update Helper" allow rule on 8080 (4946)
- Guest (.101) loaded the portal — segmentation bypassed.
- 11:06:30 — rogue rule removed (4948)
- 11:07:03 — FF-BLOCK Guest Zone re-enabled (4947)
- Retest: Guest timed out again.
