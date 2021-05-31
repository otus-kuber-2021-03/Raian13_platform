FROM nginx:alpine

ARG USERID=1001

RUN rm /etc/nginx/conf.d/default.conf && chown ${USERID} /var/cache/nginx && chmod 775 /var/run

COPY nginx-config /etc/nginx/conf.d
COPY app /app

USER ${USERID}

EXPOSE 8000

ENTRYPOINT ["nginx", "-g", "daemon off;"]
