#!/command/with-contenv bash
# shellcheck shell=bash
# /etc/cont-init.d/10-splunk-config.sh
# Runs once at container start (before s6-rc services).
# Reads Home Assistant options, performs first-boot init, and writes Splunk configs.
set -euo pipefail

CONFIG="/data/options.json"
SPLUNK_HOME="/opt/splunkforwarder"
SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"
LOCAL_DIR="${SPLUNK_HOME}/etc/system/local"
INIT_FLAG="${SPLUNK_HOME}/etc/.ha_initialized"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[cont-init] $*"; }
err()  { echo "[cont-init] ERROR: $*" >&2; exit 1; }

# ── Validate options file ─────────────────────────────────────────────────────
[[ -f "${CONFIG}" ]] || err "Options file not found at ${CONFIG}"

# ── Read Home Assistant configuration options ─────────────────────────────────
DEPLOYMENT_SERVER=$(jq -r '.deployment_server // ""'  "${CONFIG}")
TCP_LISTEN=$(jq -r        '.tcp_listen       // false' "${CONFIG}")
TCP_PORT=$(jq -r          '.tcp_port         // 9997'  "${CONFIG}")
SPLUNK_PASSWORD=$(jq -r   '.splunk_password  // "ChangeMe1!"' "${CONFIG}")

mkdir -p "${LOCAL_DIR}"

# ── First-boot: accept licence and seed the admin password ───────────────────
# This block only runs once.  The flag file persists in the Splunk install dir.
if [[ ! -f "${INIT_FLAG}" ]]; then
    log "First boot detected – accepting licence and initialising Splunk UF…"

    # Start (daemonised), then immediately stop to let Splunk do its
    # internal first-run setup (write default configs, accept EULA, etc.)
    "${SPLUNK_BIN}" start \
        --accept-license \
        --answer-yes \
        --no-prompt \
        --seed-passwd "${SPLUNK_PASSWORD}" \
        2>&1 || err "Splunk first-run start failed."

    "${SPLUNK_BIN}" stop 2>&1 || true

    touch "${INIT_FLAG}"
    log "First-boot initialisation complete."
fi

# ── Deployment Server (management / apps) ────────────────────────────────────
if [[ -n "${DEPLOYMENT_SERVER}" ]]; then
    log "Deployment server → ${DEPLOYMENT_SERVER}"
    cat > "${LOCAL_DIR}/deploymentclient.conf" <<EOF
[deployment-client]

[target-broker:deploymentServer]
targetUri = ${DEPLOYMENT_SERVER}
EOF
else
    log "No deployment server configured – running standalone."
    rm -f "${LOCAL_DIR}/deploymentclient.conf"
fi

# ── TCP listener (receive data / syslog from other sources) ──────────────────
if [[ "${TCP_LISTEN}" == "true" ]]; then
    log "Enabling TCP listener on port ${TCP_PORT}"
    cat > "${LOCAL_DIR}/inputs.conf" <<EOF
[splunktcp://:${TCP_PORT}]
connection_host = ip
disabled = false
EOF
else
    log "TCP listener disabled."
    rm -f "${LOCAL_DIR}/inputs.conf"
fi

log "Configuration written – handing off to s6-rc."
