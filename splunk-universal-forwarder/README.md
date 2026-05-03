# Splunk Universal Forwarder — Home Assistant Add-on

Runs a [Splunk Universal Forwarder](https://www.splunk.com/en_us/download/universal-forwarder.html)
inside Home Assistant, shipping logs and events to any Splunk deployment.

**Supported architectures:** `amd64` · `aarch64`

---

## How it works

The add-on is a thin wrapper around the official `splunk/universalforwarder`
Docker image (Red Hat UBI8). On start, `run.sh` reads Home Assistant's
`options.json`, exports the appropriate `SPLUNK_*` environment variables, and
hands off to `/sbin/entrypoint.sh start-service` — the Splunk image's own
container-native startup path. Splunk handles first-boot licence acceptance,
password seeding, and all internal initialisation.

---

## Configuration

### `deployment_server`

Address of your Splunk Deployment Server for centralised app and config
management. Format: `host:port` (default management port is `8089`).

```yaml
deployment_server: "192.168.1.50:8089"
```

Leave blank to run the forwarder standalone without central management.

---

### `tcp_listen`

Enable a Splunk TCP input so this forwarder can receive data from other
forwarders or syslog sources.

```yaml
tcp_listen: true
```

---

### `tcp_port`

TCP port to listen on when `tcp_listen` is enabled. Defaults to `9997`.

```yaml
tcp_port: 9997
```

> **Note:** The *Network* section of the add-on page maps this container port
> to a host port. If you change `tcp_port`, update the host port mapping too.

---

### `splunk_password`

Admin password for the local Splunk UF management interface. Splunk requires
at least 8 characters including mixed case and at least one digit or symbol.

```yaml
splunk_password: "S3cur3Pa$$word"
```

---

## Example configuration

```yaml
deployment_server: "splunk-ds.lan:8089"
tcp_listen: true
tcp_port: 9997
splunk_password: "S3cur3Pa$$word"
```

---

## Ports

| Port | Protocol | Active when |
|------|----------|-------------|
| 9997 | TCP | `tcp_listen: true` |
