# --- STAGE 1: Build the React Application ---
# Use an official Node.js image as the builder environment
FROM node:18-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to leverage Docker cache
COPY package*.json ./

# Install all dependencies based on package-lock.json
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Build the production-ready static files
RUN npm run build


# --- STAGE 2: Serve the Application with Nginx ---
# Use a lightweight Nginx image for the final container
FROM nginx:1.27-alpine

# Copy the static files from the 'builder' stage to the Nginx public directory
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port 80 to the outside world
EXPOSE 80

# Command to start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]