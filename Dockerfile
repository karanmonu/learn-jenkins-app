# STAGE 1: Build the React Application
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# STAGE 2: Serve the Application with Nginx
FROM nginx:1.27-alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["sh", "-c", "echo '--- Listing Nginx config directory ---'; ls -l /etc/nginx/conf.d/; echo '--- Contents of default.conf ---'; cat /etc/nginx/conf.d/default.conf; echo '--- Container will now sleep ---'; sleep 300"]