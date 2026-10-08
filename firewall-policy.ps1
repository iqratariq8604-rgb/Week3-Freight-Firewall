# ============================================================
# ABC Freight Forwarders - Firewall Policy (Week 3 Lab)
# Run in PowerShell as Administrator on the server (host laptop)
# ============================================================

# --- Step 1: Enable auditing (logging is OFF by default) ---
auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable
auditpol /set /subcategory:"Filtering Platform Packet Drop" /success:enable /failure:enable
auditpol /set /subcategory:"MPSSVC Rule-Level Policy Change" /success:enable /failure:enable

# --- Step 2: Zone rules ---
# Finance (.40-.49) may reach the Billing Portal
New-NetFirewallRule -DisplayName "FF-ALLOW Billing Portal from Finance" -Direction Inbound -Protocol TCP -LocalPort 8080 -RemoteAddress 192.168.56.40-192.168.56.49 -Action Allow

# IT Admin (.10-.19) may reach the Billing Portal for maintenance
New-NetFirewallRule -DisplayName "FF-ALLOW Billing Portal from IT" -Direction Inbound -Protocol TCP -LocalPort 8080 -RemoteAddress 192.168.56.10-192.168.56.19 -Action Allow

# Guest Wi-Fi (.100-.199) blocked from everything
New-NetFirewallRule -DisplayName "FF-BLOCK Guest Zone" -Direction Inbound -RemoteAddress 192.168.56.100-192.168.56.199 -Action Block

# Warehouse (.50-.59) blocked from everything
New-NetFirewallRule -DisplayName "FF-BLOCK Warehouse Zone" -Direction Inbound -RemoteAddress 192.168.56.50-192.168.56.59 -Action Block

# Office (.30-.39): no rule = Windows default inbound deny

# --- Review: list all FF- rules ---
Get-NetFirewallRule -DisplayName "FF-*" | Select-Object DisplayName, Enabled, Direction, Action

# ============================================================
# TAMPERING SIMULATION (test only)
# ============================================================
# Disable-NetFirewallRule -DisplayName "FF-BLOCK Guest Zone"
# New-NetFirewallRule -DisplayName "Windows Update Helper" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow

# FIX
# Remove-NetFirewallRule -DisplayName "Windows Update Helper"
# Enable-NetFirewallRule -DisplayName "FF-BLOCK Guest Zone"

# ============================================================
# CLEANUP (run only AFTER the video is recorded)
# ============================================================
# Remove-NetFirewallRule -DisplayName "FF-*"
# auditpol /set /subcategory:"Filtering Platform Connection" /success:disable /failure:disable
# auditpol /set /subcategory:"Filtering Platform Packet Drop" /success:disable /failure:disable
# auditpol /set /subcategory:"MPSSVC Rule-Level Policy Change" /success:disable /failure:disable
