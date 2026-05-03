FROM splunk/universalforwarder:latest

# ── The base image is Red Hat UBI8; use microdnf (not apt-get) ───────────────
USER root

# jq is in the UBI8 AppStream repo — available via microdnf with no extra config.
RUN microdnf install -y jq \
    && microdnf clean all

# Thin wrapper: reads HA options.json → exports SPLUNK_* env vars →
# delegates to the official Splunk Docker entrypoint.
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Home Assistant bind-mounts the add-on data volume here.
VOLUME ["/data"]

# Override the default CMD; ENTRYPOINT stays as the image's /sbin/tini.
CMD ["/run.sh"]
