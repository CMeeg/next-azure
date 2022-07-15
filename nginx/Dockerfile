# Base on offical NGINX Alpine image
FROM nginx:alpine

# Remove any existing config files
RUN rm /etc/nginx/conf.d/*
RUN rm /etc/nginx/nginx.conf

# Copy config files
COPY ./includes /etc/nginx/includes
COPY ./conf /etc/nginx/conf.d
COPY ./nginx.conf /etc/nginx/nginx.conf

# Expose the listening port
EXPOSE 8080

# Launch NGINX
CMD ["nginx", "-g", "daemon off;"]
