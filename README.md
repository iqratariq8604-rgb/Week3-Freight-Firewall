# Network Segmentation & Firewall Policy Review — ABC Freight Forwarders (Lab)

**Week 3 — Professional Advanced Build** | Member 3 (Individual Contributor) | Primary Tool: **Windows Event Viewer**

---

## 1. Executive Summary

I designed and tested a network segmentation plan and firewall policy for a fictional independent freight forwarder, ABC Freight Forwarders. The network was split into five zones (IT, Office, Finance, Warehouse, Guest Wi-Fi), and Windows Defender Firewall rules were written so that only Finance and IT can reach the company Billing Portal. Every allowed and blocked connection was verified in Windows Event Viewer. All 5 zone tests passed. I then simulated an insider tampering attack that silently opened the portal to the Guest zone, detected both malicious changes in Event Viewer within seconds of each other, and reversed them.

---

## 2. Scope Statement

**Client (fictional):** ABC Freight Forwarders — an independent freight forwarder (~25 staff) that handles shipping documents, customs data, and client billing.

**Business problem:** All devices (staff PCs, finance, warehouse scanners, driver guest Wi-Fi) share one flat network. A single compromised device, such as a driver's phone on guest Wi-Fi, could reach the billing system. Freight forwarders are common targets for invoice fraud and ransomware, so the billing system needs to be isolated.

**In scope**
- Designing network zones (segmentation) based on business roles
- Writing a zone-to-service firewall policy matrix
- Implementing the policy with Windows Defender Firewall
- Verifying allowed and blocked traffic with Windows Event Viewer
- Detecting unauthorized firewall rule changes (tampering)

**Out of scope**
- Physical switches, VLAN hardware, or a dedicated perimeter firewall
- Outbound (egress) filtering
- Cloud services and email security

**Lab limitation (honest note):** Zones are simulated with IP ranges inside one host-only network (192.168.56.0/24). In a real office, zones would be separate VLANs with a router/firewall between them. The host laptop acts as the company server.

**How this differs from Weeks 1 and 2:** Week 1 hardened a single endpoint (real estate agency) and Week 2 detected failed logins on one machine (retail, Event ID 4625). Week 3 moves from the single machine to the **network**: controlling which groups of devices can talk to which service, proving it with Filtering Platform events (5152/5156), and monitoring the firewall itself for tampering (4946/4947/4948).

---

## 3. Lab Environment

| Component | Details | Role |
|---|---|---|
| Host laptop | Windows 10 (build 19045), 192.168.56.1 | Company server (Billing Portal) |
| Kali Linux 2026.2 | VirtualBox VM, Host-only adapter (eth1) | Test client acting as all 5 zones |
| Billing Portal | PowerShell HttpListener, TCP 8080 | Business service being protected |
| Windows Defender Firewall | Inbound rules scoped by remote IP | Policy enforcement |
| Windows Event Viewer | Security log, custom XPath filters | Verification and detection |
| Tools on Kali | `nmap`, `curl --interface`, `ip addr` | Scanning and zone testing |

Kali's Host-only IP and the host's adapter:

![Kali host-only IP](screenshots/01a-kali-hostonly-ip.png)
![Host ipconfig](screenshots/01b-host-ipconfig.png)

---

## 4. Segmentation Design

| Zone | IP Range | Who | Needs Billing Portal? |
|---|---|---|---|
| IT / Admin | 192.168.56.10 – .19 | IT staff | Yes (maintenance) |
| Office Staff | 192.168.56.30 – .39 | Operations, sales | No |
| Finance | 192.168.56.40 – .49 | Accounts team | **Yes (invoicing)** |
| Warehouse | 192.168.56.50 – .59 | Scanners, CCTV | No |
| Guest Wi-Fi | 192.168.56.100 – .199 | Drivers, visitors | **Never** |

![Segmentation diagram](screenshots/00-segmentation-diagram.png)

---

## 5. Firewall Policy Matrix

| # | Rule Name | Source | Port | Action | Business Reason |
|---|---|---|---|---|---|
| 1 | FF-ALLOW Billing Portal from Finance | .40 – .49 | TCP 8080 | Allow | Finance creates invoices |
| 2 | FF-ALLOW Billing Portal from IT | .10 – .19 | TCP 8080 | Allow | IT maintains the system |
| 3 | FF-BLOCK Guest Zone | .100 – .199 | All | Block | Drivers need internet only |
| 4 | FF-BLOCK Warehouse Zone | .50 – .59 | All | Block | Scanners/CCTV never need the server |
| — | (no rule) | Office .30 – .39 | All | Default Deny | Least privilege: not needed for their job |

All custom rules use the `FF-` prefix so they are easy to audit. Script: [`scripts/firewall-policy.ps1`](scripts/firewall-policy.ps1)

![Rules created 1](screenshots/07a-rules-allow-finance-it.png)
![Rules created 2](screenshots/07b-rules-block-guest.png)
![Rules created 3](screenshots/07c-rules-block-warehouse.png)

---

## 6. Implementation Steps

**Step 1 — Baseline.** Ping from Kali to the host failed (174 sent, 0 received).

![Ping blocked](screenshots/01c-ping-blocked.png)

**Step 2 — Enable auditing.** Windows does not log allowed/blocked connections or rule changes by default.

![auditpol](screenshots/02-auditpol-enabled.png)

**Step 3 — Baseline scan from the Guest zone.** All 1000 common TCP ports were filtered.

![nmap before](screenshots/03-nmap-before-all-filtered.png)

The drops were visible in Event Viewer (Event 5152, Source 192.168.56.101):

![First 5152](screenshots/04-eventviewer-kali-blocked.png)

**Step 4 — Start the Billing Portal** on TCP 8080 ([`scripts/billing-portal.ps1`](scripts/billing-portal.ps1)).

![Portal running](screenshots/05-billing-portal-running.png)

Before any rules, the Guest zone could not reach it:

![Guest blocked before rules](screenshots/06a-guest-blocked-before-rules.png)

**Step 5 — Create the four `FF-` rules** (Section 5).

**Step 6 — Give Kali one IP per zone** ([`scripts/kali-zone-tests.sh`](scripts/kali-zone-tests.sh)).

![Kali zone IPs](screenshots/08-kali-zone-ips.png)

**Step 7 — Test every zone and verify in Event Viewer** (Section 7).

**Step 8 — Simulate tampering, detect it, and fix it** (Section 8, F5).

---

## 7. Testing & Evidence

### Zone access tests (after rules)

| Test | Zone | Source IP | Expected | Result | Evidence | Status |
|---|---|---|---|---|---|---|
| 1 | Guest | .101 | Block | Timed out | Event 5152 | ✅ PASS |
| 2 | Finance | .45 | Allow | Page loaded | Event 5156 + portal log | ✅ PASS |
| 3 | IT Admin | .15 | Allow | Page loaded | Portal log | ✅ PASS |
| 4 | Office | .35 | Block (default deny) | Timed out | — | ✅ PASS |
| 5 | Warehouse | .55 | Block | Timed out | — | ✅ PASS |

**Result: 5 / 5 passed.**

![5 of 5 tests](screenshots/09-zone-tests-5-of-5-pass.png)

**Server-side proof:** the Billing Portal's own log shows requests only from `.45` (Finance) and `.15` (IT). Blocked zones never reached the service.

![Portal log](screenshots/10-portal-log-finance-it-only.png)

**Allowed — Event 5156:** Finance (192.168.56.45) → 192.168.56.1, port 8080, Audit Success.

![5156 Finance allowed](screenshots/11c-eventviewer-5156-finance-allowed.png)

**Blocked — Event 5152:** Guest (192.168.56.101) → port 8080, Audit Failure. One event from before the rules (08:55) and one after (09:34):

![5152 before](screenshots/12b-guest-blocked-8080-before-rules.png)
![5152 after](screenshots/12c-guest-blocked-8080-after-rules.png)

### Event IDs used

| Event ID | Meaning | Where |
|---|---|---|
| 5152 | Packet dropped (blocked) | Security log |
| 5156 | Connection allowed | Security log |
| 4946 | Firewall rule added | Security log |
| 4947 | Firewall rule modified | Security log |
| 4948 | Firewall rule deleted | Security log |

Filters used: [`scripts/eventviewer-filters.xml`](scripts/eventviewer-filters.xml)

---

## 8. Findings & Fixes

**F1 — Security logging disabled by default.** Windows does not log allowed/blocked connections or rule changes until audit subcategories are enabled. *Fix:* enabled via `auditpol`.

**F2 — Everything blocked, including needed services.** All 1000 ports were filtered from the Guest zone. Secure, but unusable for a business that needs Finance to reach billing. *Fix:* scoped allow rules per zone instead of opening ports to everyone.

**F3 — Log noise.** The Security log held 27,000+ events, mostly the host's own internet and Chrome traffic. A single Guest scan produced 2,010 drop events. Filtering by Event ID alone was not enough. *Fix:* XPath filters by Event ID + source IP + destination port.

![Noise: internet traffic](screenshots/11a-log-noise-internet-traffic.png)
![Noise: Chrome](screenshots/11b-log-noise-chrome.png)
![2010 drops from nmap](screenshots/12a-nmap-scan-2010-drops.png)

**F4 — Bug in the Billing Portal script.** The client IP printed empty because it was read after the connection was closed. *Fix:* read `RemoteEndPoint` before `Response.Close()`.

![Bug: empty IP](screenshots/06b-portal-bug-empty-ip.png)

**F5 — Tampering breaks segmentation silently.** Acting as an insider with admin rights, I disabled `FF-BLOCK Guest Zone` and added an allow rule disguised as "Windows Update Helper". The Guest zone then loaded the Billing Portal.

![Tampering: Guest got in](screenshots/13-tampering-guest-got-in.png)

Both changes were detected in Event Viewer:

![4946 rogue rule](screenshots/14-detected-4946-rogue-rule.png)
![4947 block disabled](screenshots/15-detected-4947-block-disabled.png)

The fix was also logged:

![4948 rogue deleted](screenshots/16a-fix-4948-rogue-deleted.png)
![4947 block restored](screenshots/16b-fix-4947-block-restored.png)

| Time | Event ID | Action |
|---|---|---|
| 10:49:09 | 4947 | FF-BLOCK Guest Zone disabled |
| 10:49:44 | 4946 | Rogue rule "Windows Update Helper" added |
| After | — | Guest (.101) loaded the Billing Portal |
| 11:06:30 | 4948 | Rogue rule deleted |
| 11:07:03 | 4947 | FF-BLOCK Guest Zone re-enabled |

The Rule IDs in the events matched the original rules exactly (`{4673825a-…}` for the Guest block, `{984e45c3-…}` for the rogue rule), confirming which rules were touched. On retest, the Guest zone was blocked again:

![Retest](screenshots/17-retest-guest-blocked-again.png)

**F6 — Events do not show who made the change.** Rule-change events showed `User: N/A`, so the log proves *what* changed and *when*, but not *who*. (See improvements.)

---

## 9. Key Decisions & Trade-offs

- **Default deny instead of blocking bad zones one by one.** Only zones with a business need get an allow rule. Any zone I forget (like Office) is blocked automatically, which is safer than trying to list every bad source.
- **Explicit block rules for Guest and Warehouse, even though default deny already blocks them.** In Windows Firewall, block rules win over allow rules, so if someone later adds a broad allow rule by mistake, Guest still stays blocked. The tampering test proved this: the attacker had to *disable* the block rule first, which created an extra log event.
- **IT gets access, Office does not.** IT maintains the system; Office staff have no billing duties. Giving Office access would widen the attack surface for no business benefit.
- **IP-range zones on one network instead of real VLANs.** This kept the lab free and runnable on one laptop. The trade-off is that the zones are not isolated at layer 2, which I document as a limitation.
- **Host laptop as the server instead of a separate Windows VM.** Saved RAM and setup time; all rules are scoped to the lab range and removed after testing.

---

## 10. What I Would Improve With More Time

- **Find out *who* made a change:** enable PowerShell Script Block Logging (Event 4104) so the exact tampering commands and user are recorded.
- **Alert automatically:** forward logs to a SIEM such as Wazuh and raise an alert whenever Event 4946, 4947 or 4948 appears.
- **Real segmentation:** build actual VLANs with pfSense between zones so isolation is enforced at the network level, not only on the server.
- **Egress rules:** restrict warehouse devices to only the internet destinations they need.

---

## 11. Repository Structure

```
Week3-Freight-Firewall/
├── README.md
├── SUMMARY.md
├── CHANGELOG.md
├── scripts/
│   ├── firewall-policy.ps1
│   ├── billing-portal.ps1
│   ├── kali-zone-tests.sh
│   └── eventviewer-filters.xml
└── screenshots/   (28 images, numbered by stage)
```

## 12. Cleanup

After recording the video, run the cleanup section at the bottom of `scripts/firewall-policy.ps1` to remove all `FF-` rules and turn auditing back off.
