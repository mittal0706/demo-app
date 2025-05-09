# Build stage
FROM node:12.18.1 AS builder

WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Production stage
FROM node:12.18.1-slim

WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production

# Copy built application from builder stage
COPY --from=builder /usr/src/app .

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["npm", "start"]