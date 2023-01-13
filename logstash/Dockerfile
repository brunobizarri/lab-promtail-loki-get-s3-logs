FROM logstash:8.5.3
RUN for i in {1..3}; do bin/logstash-plugin install logstash-output-loki && break || sleep 2; done
CMD ["/usr/local/bin/docker-entrypoint"]