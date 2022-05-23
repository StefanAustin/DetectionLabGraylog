#!/bin/bash

sudo apt-get update && sudo apt-get upgrade
sudo apt-get install apt-transport-https openjdk-11-jre-headless uuid-runtime pwgen

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

sudo systemctl daemon-reload
sudo systemctl enable mongod.service
sudo systemctl restart mongod.service
sudo systemctl --type=service --state=active | grep mongod


wget -q https://artifacts.elastic.co/GPG-KEY-elasticsearch -O myKey
sudo apt-key add myKey
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch-oss

sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOT
cluster.name: graylog
action.auto_create_index: false
EOT

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service
sudo systemctl --type=service --state=active | grep elasticsearch

wget https://packages.graylog2.org/repo/packages/graylog-4.3-repository_latest.deb
sudo dpkg -i graylog-4.3-repository_latest.deb
sudo apt-get update && sudo apt-get install graylog-server graylog-enterprise-plugins graylog-integrations-plugins graylog-enterprise-integrations-plugins

cat >/etc/graylog/server/server.conf <<EOF
############################
# GRAYLOG CONFIGURATION FILE
############################
is_leader = true
node_id_file = /etc/graylog/server/node-id
password_secret = 4bbdd5a829dba09d7a7ff4c1367be7d36a017b4267d728d31bd264f63debeaa6
root_password_sha2 = 4bbdd5a829dba09d7a7ff4c1367be7d36a017b4267d728d31bd264f63debeaa6
bin_dir = /usr/share/graylog-server/bin
data_dir = /var/lib/graylog-server
plugin_dir = /usr/share/graylog-server/plugin
http_bind_address = 192.168.56.105:9111
#http_bind_address = [2001:db8::1]:9000
rotation_strategy = count
elasticsearch_max_docs_per_index = 20000000
elasticsearch_max_number_of_indices = 20
retention_strategy = delete
elasticsearch_shards = 4
elasticsearch_replicas = 0
elasticsearch_index_prefix = graylog
allow_leading_wildcard_searches = false
allow_highlighting = false
elasticsearch_analyzer = standard
output_batch_size = 500
output_flush_interval = 1
output_fault_count_threshold = 5
output_fault_penalty_seconds = 30
processbuffer_processors = 5
outputbuffer_processors = 3
processor_wait_strategy = blocking
ring_size = 65536
inputbuffer_ring_size = 65536
inputbuffer_processors = 2
inputbuffer_wait_strategy = blocking
message_journal_enabled = true
message_journal_dir = /var/lib/graylog-server/journal
lb_recognition_period_seconds = 3
mongodb_uri = mongodb://localhost/graylog
mongodb_max_connections = 1000
mongodb_threads_allowed_to_block_multiplier = 5
proxied_requests_thread_pool_size = 32
EOF

sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service
sudo systemctl --type=service --state=active | grep graylog

sudo apt-get install filebeat

wget https://packages.graylog2.org/repo/packages/graylog-sidecar-repository_1-2_all.deb
sudo dpkg -i graylog-sidecar-repository_1-2_all.deb
sudo apt-get update && sudo apt-get install graylog-sidecar

cat >/etc/graylog/sidecar/sidecar.yml <<EOF
# The URL to the Graylog server API.
server_url: "http://192.168.56.105:9111/api/"
server_api_token: "knvdjjuv1jgv2g0hih6lv60eueoj7cahs46a7grvcog7l661ake"
# Example:
#     list_log_files:
#       - "/var/log/nginx"
#       - "/opt/app/logs"
#
# Default: empty list
#list_log_files: []

# Directory where the sidecar stores internal data.
#cache_path: "/var/cache/graylog-sidecar"

# Directory where the sidecar stores logs for collectors and the sidecar itself.
#log_path: "/var/log/graylog-sidecar"

# The maximum size of the log file before it gets rotated.
#log_rotate_max_file_size: "10MiB"

# The maximum number of old log files to retain.
#log_rotate_keep_files: 10

# Directory where the sidecar generates configurations for collectors.
#collector_configuration_directory: "/var/lib/graylog-sidecar/generated"

# A list of binaries which are allowed to be executed by the Sidecar. An empty list disables the whitelist feature.
# Wildcards can be used, for a full pattern description see https://golang.org/pkg/path/filepath/#Match
# Example:
#     collector_binaries_whitelist:
#       - "/usr/bin/filebeat"
#       - "/opt/collectors/*"
#
# Example disable whitelisting:
#     collector_binaries_whitelist: []
#
# Default:
# collector_binaries_whitelist:
#  - "/usr/bin/filebeat"
#  - "/usr/bin/packetbeat"
#  - "/usr/bin/metricbeat"
#  - "/usr/bin/heartbeat"
#  - "/usr/bin/auditbeat"
#  - "/usr/bin/journalbeat"
#  - "/usr/share/filebeat/bin/filebeat"
#  - "/usr/share/packetbeat/bin/packetbeat"
#  - "/usr/share/metricbeat/bin/metricbeat"
#  - "/usr/share/heartbeat/bin/heartbeat"
#  - "/usr/share/auditbeat/bin/auditbeat"
#  - "/usr/share/journalbeat/bin/journalbeat"
#  - "/usr/bin/nxlog"
#  - "/opt/nxlog/bin/nxlog"
EOF

#input is missing

sudo graylog-sidecar -service install
sudo systemctl start graylog-sidecar
