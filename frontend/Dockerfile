# Nginx serves only the static files from public/ (CSS, images, JS)
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY public/ /usr/share/nginx/html/
EXPOSE 80
