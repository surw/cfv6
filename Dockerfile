FROM alpine
RUN apk add bind-tools jq curl bash
COPY v6reload.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["/start.sh"]
