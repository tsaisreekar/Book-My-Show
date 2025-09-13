# Use Node.js 18
FROM node:18

# Set working directory
WORKDIR /app

# Copy dependency files first
COPY package.json package-lock.json ./

# Install dependencies (force PostCSS fix included)
RUN npm install postcss@8.4.21 postcss-safe-parser@6.0.0 --legacy-peer-deps \
    && npm install

# Copy the rest of the project
COPY . .

# Expose app port
EXPOSE 3000

# Fix OpenSSL issue
ENV NODE_OPTIONS=--openssl-legacy-provider
ENV PORT=3000

# Run the app
CMD ["npm", "start"]
