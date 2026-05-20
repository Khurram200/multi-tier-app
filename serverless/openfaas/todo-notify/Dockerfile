FROM ghcr.io/openfaas/of-watchdog:0.10.14 AS watchdog
FROM node:20-alpine

WORKDIR /home/node/app

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

COPY handler.js package.json ./

ENV fprocess="node handler.js"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:3000"
ENV write_timeout="60s"
ENV read_timeout="60s"
ENV exec_timeout="0"
ENV cgi_headers="true"
ENV combine_output="false"

HEALTHCHECK --interval=5s CMD [ -e /tmp/.lock ] || exit 1

USER node

CMD ["fwatchdog"]
