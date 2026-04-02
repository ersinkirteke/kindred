# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Create non-root user and give ownership of /app
RUN addgroup -g 1001 -S nodejs && adduser -S nestjs -u 1001 && chown nestjs:nodejs /app

# Copy built application and dependencies
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nestjs:nodejs /app/package*.json ./
COPY --from=builder --chown=nestjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nestjs:nodejs /app/prisma.config.ts ./
COPY --from=builder --chown=nestjs:nodejs /app/config ./dist/config

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "const http=require('http');const data=JSON.stringify({query:'{health}'});const req=http.request({hostname:'localhost',port:3000,path:'/v1/graphql',method:'POST',headers:{'Content-Type':'application/json','Content-Length':data.length}},(r)=>{process.exit(r.statusCode===200?0:1)});req.write(data);req.end();"

# Start application
CMD ["node", "dist/src/main"]
