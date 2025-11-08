FROM debian:bullseye

# Install Redis
RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Create Redis user and group
RUN addgroup --system redisgroup && \
    adduser --system --ingroup redisgroup redisuser

# Create config directory
RUN mkdir -p /usr/local/etc/redis

# Copy configuration
COPY conf/redis.conf /usr/local/etc/redis/redis.conf
RUN chown redisuser:redisgroup /usr/local/etc/redis/redis.conf

USER redisuser

EXPOSE 6379

CMD ["sh", "-c", "redis-server /usr/local/etc/redis/redis.conf --requirepass \"$REDIS_PASSWORD\""]
