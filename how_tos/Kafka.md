# Kafka

[GMT20220310-143215_Recording_1920x1050.mp4](Kafka%20cedfc4e83f1d4fb58824e34a993771bb/GMT20220310-143215_Recording_1920x1050.mp4)

### Env to connect into Kafka

download binary and extract:

<aside>
⚠️ check if latest version isn’t 3.1.0: [https://mirrors.estointernet.in/apache/kafka/](https://mirrors.estointernet.in/apache/kafka/)

</aside>

```yaml
wget --no-check-certificate \
https://mirrors.estointernet.in/apache/kafka/3.1.0/kafka_2.13-3.1.0.tgz && \
tar -xvzf kafka_2.13-3.1.0.tgz && cd kafka_2.13-3.1.0/bin
```

OR run docker container directly:

```bash
docker run -it mesosphere/kafka-client:latest bash
```

### Create Topics with partitions

define environment variables:

<aside>
⚠️ kafka URL in CICD: `kubectl  get vs | grep kafka | awk '{ print $3 }’`

</aside>

```bash
export KAFKA_URL=kafka.**<YOUR-CICD>**.cicd.webapp.me:9092
export KAFKA_TOPIC=input_test
```

provide your cicd build:

```bash
./kafka-topics.sh --create --bootstrap-server $KAFKA_URL --replication-factor 1 --partitions 1 --topic $KAFKA_TOPIC
```

result:


### create new endpoint page:


- **Kafka brokers:** the kafka URL in CICD env
- **Input Topics:** the topic previously

```yaml
input_test
```

### commands:

python:

```python
from kafka import KafkaProducer
from kafka.errors import KafkaError
import time
import os

kafka_url = os.getenv("KAFKA_URL")
kafka_topic = os.getenv("KAFKA_TOPIC")

producer = KafkaProducer(bootstrap_servers=[kafka_url])
for i in range(100000000):
    time.sleep(0.1)
    future = producer.send(kafka_topic, b"input_fsdfdsfsdgdfgsdfgsdfgdfgdsfgdgdgdgdgdgdsfgdfgsdfgtest")
    print("{}".format(i), end='\r')
```

bash:

```bash
# create new topic:
./kafka-topics.sh --create --zookeeper 40.84.139.218:2181 --replication-factor 1 --partitions 1 --topic new_topic_name

# write message to stream:
./kafka-console-producer.sh --topic $KAFKA_TOPIC --bootstrap-server $KAFKA_URL
# enter msg and press enter to send

# Reading msg from stream:
./kafka-console-consumer.sh --topic $KAFKA_TOPIC --from-beginning --bootstrap-server 40.84.139.218:9092
# you can remove --from-begining if you dont need it

# list groups:
./kafka-consumer-groups.sh --bootstrap-server 40.84.139.218:9092 --list

# describe group:
./kafka-consumer-groups.sh --bootstrap-server 40.84.139.218:9092 --group group_name --describe

#list topics: 
./kafka-topics.sh --bootstrap-server=$KAFKA_URL --list

#Partitions count :     
./kafka-topics.sh --describe --bootstrap-server=$KAFKA_URL --topic _aut_input
```

### Find Consumer group:

```bash
./kafka-consumer-groups.sh --bootstrap-server 40.84.139.218:9092 --list
```

### stop kafka network:

```bash
kc edit vs kafka-bootstrap

#add a sign/number to the hosts to disable it:
hosts:
  - kafka.disableeks-rofl3368.webapp.me
```

```bash
# list topics: 
./kafka-topics.sh --bootstrap-server=$KAFKA_URL --list

# Partitions count :     
./kafka-topics.sh --describe --bootstrap-server=$KAFKA_URL --topic _aut_input
```

# create new kafka

create a **docker-compose.yml** file

```bash
version: '2.1'
services:
  zoo1:
    image: zookeeper:3.4.9
    restart: always
    hostname: zoo1
    ports:
      - "2181:2181"
    environment:
        ZOO_MY_ID: 1
        ZOO_PORT: 2181
        ZOO_SERVERS: server.1=zoo1:2888:3888
    volumes:
      - ./full-stack/zoo1/data:/data
      - ./full-stack/zoo1/datalog:/datalog
  kafka1:
    image: confluentinc/cp-kafka:5.5.1
    hostname: kafka1
    restart: always
    ports:
      - "9092:9092"
    environment:
      KAFKA_ADVERTISED_LISTENERS: LISTENER_DOCKER_INTERNAL://kafka1:19092,LISTENER_DOCKER_EXTERNAL://${DOCKER_HOST_IP:-127.0.0.1}:9092 
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: LISTENER_DOCKER_INTERNAL:PLAINTEXT,LISTENER_DOCKER_EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: LISTENER_DOCKER_INTERNAL
      KAFKA_ZOOKEEPER_CONNECT: "zoo1:2181"
      KAFKA_BROKER_ID: 1
      KAFKA_LOG4J_LOGGERS: "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    volumes:
      - ./full-stack/kafka1/data:/var/lib/kafka/data
    depends_on:
      - zoo1
  kafka-schema-registry:
    image: confluentinc/cp-schema-registry:5.5.1
    hostname: kafka-schema-registry
    restart: always   
    ports:
      - "8081:8081"
    environment:
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://kafka1:19092
      SCHEMA_REGISTRY_HOST_NAME: kafka-schema-registry
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
    depends_on:
      - zoo1
      - kafka1
  schema-registry-ui:
    image: landoop/schema-registry-ui:0.9.5
    hostname: kafka-schema-registry-ui
    restart: always
    ports:
      - "8001:8000"
    environment:
      SCHEMAREGISTRY_URL: http://kafka-schema-registry:8081/
      PROXY: "true"
    depends_on:
      - kafka-schema-registry
  kafka-rest-proxy:
    image: confluentinc/cp-kafka-rest:5.5.1
    hostname: kafka-rest-proxy
    restart: always
    ports:
      - "8082:8082"
    environment:
      # KAFKA_REST_ZOOKEEPER_CONNECT: zoo1:2181
      KAFKA_REST_LISTENERS: http://0.0.0.0:8082/
      KAFKA_REST_SCHEMA_REGISTRY_URL: http://kafka-schema-registry:8081/
      KAFKA_REST_HOST_NAME: kafka-rest-proxy
      KAFKA_REST_BOOTSTRAP_SERVERS: PLAINTEXT://kafka1:19092
    depends_on:
      - zoo1
      - kafka1
      - kafka-schema-registry
  kafka-topics-ui:
    image: landoop/kafka-topics-ui:0.9.4
    hostname: kafka-topics-ui
    restart: always
    ports:
      - "8000:8000"
    environment:
      KAFKA_REST_PROXY_URL: "http://kafka-rest-proxy:8082/"
      PROXY: "true"
    depends_on:
      - zoo1
      - kafka1
      - kafka-schema-registry
      - kafka-rest-proxy
  kafka-connect:
    image: confluentinc/cp-kafka-connect:5.5.1
    hostname: kafka-connect
    restart: always
    ports:
      - "8083:8083"
    environment:
      CONNECT_BOOTSTRAP_SERVERS: "kafka1:19092"
      CONNECT_REST_PORT: 8083
      CONNECT_GROUP_ID: compose-connect-group
      CONNECT_CONFIG_STORAGE_TOPIC: docker-connect-configs
      CONNECT_OFFSET_STORAGE_TOPIC: docker-connect-offsets
      CONNECT_STATUS_STORAGE_TOPIC: docker-connect-status
      CONNECT_KEY_CONVERTER: io.confluent.connect.avro.AvroConverter
      CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL: 'http://kafka-schema-registry:8081'
      CONNECT_VALUE_CONVERTER: io.confluent.connect.avro.AvroConverter
      CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL: 'http://kafka-schema-registry:8081'
      CONNECT_INTERNAL_KEY_CONVERTER: "org.apache.kafka.connect.json.JsonConverter"
      CONNECT_INTERNAL_VALUE_CONVERTER: "org.apache.kafka.connect.json.JsonConverter"
      CONNECT_REST_ADVERTISED_HOST_NAME: "kafka-connect"
      CONNECT_LOG4J_ROOT_LOGLEVEL: "INFO"
      CONNECT_LOG4J_LOGGERS: "org.apache.kafka.connect.runtime.rest=WARN,org.reflections=ERROR"
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: "1"
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: "1"
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: "1"
      CONNECT_PLUGIN_PATH: '/usr/share/java,/etc/kafka-connect/jars'
    volumes:
      - ./connectors:/etc/kafka-connect/jars/
    depends_on:
      - zoo1
      - kafka1
      - kafka-schema-registry
      - kafka-rest-proxy
  kafka-connect-ui:
    image: landoop/kafka-connect-ui:0.9.7
    hostname: kafka-connect-ui
    restart: always
    ports:
      - "8003:8000"
    environment:
      CONNECT_URL: "http://kafka-connect:8083/"
      PROXY: "true"
    depends_on:
      - kafka-connect
  ksqldb-server:
    image: confluentinc/cp-ksqldb-server:5.5.1
    hostname: ksqldb-server
    restart: always
    ports:
      - "8088:8088"
    environment:
      KSQL_BOOTSTRAP_SERVERS: PLAINTEXT://kafka1:19092
      KSQL_LISTENERS: http://0.0.0.0:8088/
      KSQL_KSQL_SERVICE_ID: ksqldb-server_
    depends_on:
      - zoo1
      - kafka1
  zoonavigator:
    image: elkozmon/zoonavigator:0.8.0
    restart: always
    ports:
      - "8004:8000"
    environment:
      HTTP_PORT: 8000
      AUTO_CONNECT_CONNECTION_STRING: zoo1:2181
```

then run:

```bash
sudo docker-compose up -d
export DOCKER_HOST_IP=3.139.76.17 ### virtaul machine's IP
```