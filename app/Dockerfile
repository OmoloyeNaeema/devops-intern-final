
FROM nginx:1.27-alpine

# Accept the Git commit SHA during image building
ARG BUILD_SHA=local

# Make the build identifier available to NGINX
ENV BUILD_SHA=${BUILD_SHA}

# Remove the default NGINX website
RUN rm -rf /usr/share/nginx/html/*

# Copy our application files
COPY index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Replace the build ID placeholder with the actual build SHA
RUN sed -i "s/BUILD_ID_PLACEHOLDER/${BUILD_SHA}/g" /usr/share/nginx/html/index.html

# Run NGINX as a non-root user
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run /etc/nginx \
    && touch /var/run/nginx.pid \
    && chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
