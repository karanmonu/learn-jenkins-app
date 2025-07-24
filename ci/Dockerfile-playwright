FROM mcr.microsoft.com/playwright:v1.39.0-jammy

RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g netlify-cli serve
