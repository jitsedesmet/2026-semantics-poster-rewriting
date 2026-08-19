FROM node AS builder
WORKDIR /app/web

# Headless Chrome renders the poster to PDF. The google-chrome-stable package
# declares its own runtime dependencies, so we only add the tooling needed to
# register Google's apt repository plus the base fonts.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    fonts-liberation && \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./

RUN npm ci

COPY . .
RUN npm run build -- --base='/' && npm run build-pdf


FROM httpd:2 AS runner

COPY --from=builder /app/web/dist /usr/local/apache2/htdocs
