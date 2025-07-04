FROM postgres:latest

COPY access-graph/keys/ca.crt /var/lib/postgresql/root.crt
COPY access-graph/keys/server_docker.key /var/lib/postgresql/server.key
COPY access-graph/keys/postgres.crt /var/lib/postgresql/server.crt

# update the privileges on the .key, no need to touch the .crt
RUN chmod 600 /var/lib/postgresql/server.key
RUN chown postgres:postgres /var/lib/postgresql/server.key

CMD ["postgres", "-c", "ssl=off"]
