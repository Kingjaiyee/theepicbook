# Nginx serves only the static files from public/ (CSS, images, JS)
# nginx-unprivileged is NGINX's official image that runs as uid 101 and listens on 8080
FROM nginxinc/nginx-unprivileged:alpine
USER root
RUN rm -rf /usr/share/nginx/html/*
COPY public/ /usr/share/nginx/html/
# Run as the image's non-root nginx user (uid 101)
USER 101
EXPOSE 8080
