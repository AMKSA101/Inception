FROM debian:bullseye

# Packages installation
RUN apt update -y && apt install -y redis-server \
	&& apt autoremove -y && apt clean && \
	rm -rf /var/lib/apt/lists/*

RUN addgroup --system redisgroup && \
	adduser --system --ingroup redisgroup redisuser

EXPOSE 6379

RUN mkdir -p /usr/local/etc/redis

COPY conf/redis.conf /usr/local/etc/redis/redis.conf

RUN chown redisuser:redisgroup /usr/local/etc/redis/redis.conf

USER redisuser

CMD ["sh", "-c", "redis-server /usr/local/etc/redis/redis.conf --requirepass \"$REDIS_PASSWORD\""]
