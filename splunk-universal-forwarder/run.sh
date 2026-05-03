#!/bin/bash
# /run.sh
#
# Thin adapter between Home Assistant's options.json and the official
# Splunk Universal Forwarder Docker entrypoint.
#
# Flow:
#   1. Read /data/options.json (written by HA from the add-on config page).
#   2. Export the SPLUNK_* environment variables the Splunk entrypoint reads.
#   3. exec /sbin/entrypoint.sh start-service
#      → runs splunkd in the foreground (container-native, no daemonisation).
#        The Splunk entrypoint handles first-boot licence acceptance, password
#        seeding, and all internal Splunk initialisation automatically.
#
set -euo pipefail

CONFIG="/data/options.json"

log() { echo "[splunk-uf] $*"; }
err() { echo "[splunk-uf] ERROR: $*" >&2; exit 1; }

# ── Validate ──────────────────────────────────────────────────────────────────
[[ -f "${CONFIG}" ]] || err "Options file not found at ${CONFIG}"

# ── Read Home Assistant configuration options ─────────────────────────────────
SPLUNK_PASSWORD=$(jq -r    '.splunk_password    // "ChangeMe1!"' "${CONFIG}")
DEPLOYMENT_SERVER=$(jq -r  '.deployment_server  // ""'           "${CONFIG}")
TCP_LISTEN=$(jq -r         '.tcp_listen         // false'        "${CONFIG}")
TCP_PORT=$(jq -r           '.tcp_port           // 9997'         "${CONFIG}")

# ── Map options to the env vars the Splunk entrypoint understands ─────────────

# Required: accept the EULA non-interactively.
export SPLUNK_START_ARGS="--accept-license"

# Admin password for the local UF management interface.
export SPLUNK_PASSWORD

# Optional: Deployment Server (host:port) for centralised app management.
if [[ -n "${DEPLOYMENT_SERVER}" ]]; then
    log "Deployment server  → ${DEPLOYMENT_SERVER}"
    export SPLUNK_DEPLOYMENT_SERVER="${DEPLOYMENT_SERVER}"
else
    log "No deployment server configured – running standalone."
fi

# Optional: enable a TCP input so other forwarders / syslog sources can send here.
if [[ "${TCP_LISTEN}" == "true" ]]; then
    log "TCP listener        → port ${TCP_PORT}"
    export SPLUNK_ENABLE_LISTEN="${TCP_PORT}"
else
    log "TCP listener disabled."
fi

# ── Hand off to the official Splunk Docker entrypoint ────────────────────────
# 'start-service' is the container-native subcommand: it starts splunkd and
# keeps it in the foreground so the container (and HA add-on) stays alive.
log "Handing off to Splunk entrypoint (start-service)…"
exec /sbin/entrypoint.sh start-service
