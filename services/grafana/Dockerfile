FROM grafana/grafana

COPY grafana.ini /etc/grafana/grafana.ini

COPY ./provisioning/dashboards/sample-service.json /etc/grafana/provisioning/dashboards/sample-service.json

ENV GF_PATHS_PROVISIONING=