# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

#
# Test various errors that can happen at CREATE SINK time and check how they are reported to the user
#

> CREATE VIEW v1 (f1) AS VALUES (1);

! CREATE SINK invalid_port FROM v1
  INTO KAFKA BROKER '123:123:123'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:invalid port: invalid digit found in string

! CREATE SINK invalid_broker FROM v1
  INTO KAFKA BROKER 'localhost:1234'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Meta data fetch error: BrokerTransportFailure (Local: Broker transport failure): BrokerTransportFailure (Local: Broker transport failure)

! CREATE SINK invalid_schema_registry FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'foo'
contains:relative URL without a base

! CREATE SINK invalid_schema_registry_host FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://localhost:1234'
contains:tcp connect error

! CREATE SINK invalid_partition_count FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (partition_count = a)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:partition count for sink topics must be an integer

! CREATE SINK invalid_partition_count FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (partition_count = -2)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:partition count for sink topics must be a positive integer or -1 for broker default

! CREATE SINK invalid_replication_factor FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (replication_factor = a)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:replication factor for sink topics must be an integer

! CREATE SINK invalid_replication_factor FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (replication_factor = -2)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:replication factor for sink topics must be a positive integer or -1 for broker default

! CREATE SINK invalid_consistency FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (consistency_topic = -2)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:consistency_topic must be a string

! CREATE SINK invalid_acks FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (acks = foo)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Invalid value for configuration property "request.required.acks" acks foo

! CREATE SINK invalid_key FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  KEY(f2)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:No such column: f2

#
# Retention options
#
! CREATE SINK invalid_retention_ms FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (retention_ms = a)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:retention ms for sink topics must be an integer

! CREATE SINK invalid_retention_ms FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (retention_ms = -2)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:retention ms for sink topics must be greater than or equal to -1

! CREATE SINK invalid_retention_bytes FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (retention_bytes = a)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:retention bytes for sink topics must be an integer

! CREATE SINK invalid_retention_bytes FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (retention_bytes = -2)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:retention bytes for sink topics must be greater than or equal to -1

#
# Sink dependencies
#

> CREATE SINK s1 FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'

! CREATE SINK s2 FROM s1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:catalog item 'materialize.public.s1' is a sink and so cannot be depended upon

! CREATE VIEW v2 AS SELECT * FROM s1
contains:catalog item 'materialize.public.s1' is a sink and so cannot be depended upon

! SELECT * FROM s1
contains:catalog item 'materialize.public.s1' is a sink and so cannot be depended upon

> DROP SINK s1

#
# SSL-related options
#

! CREATE SINK invalid_security_protocol FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (security_protocol = 'FOO')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:creating admin client failed: Client config error: Invalid value "FOO" for configuration property "security.protocol" security.protocol FOO

! CREATE SINK ssl_on_non_ssl_broker FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (security_protocol = 'SSL')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Meta data fetch error: BrokerTransportFailure (Local: Broker transport failure)

! CREATE SINK invalid_ssl_certificate_location FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (security_protocol = SSL , ssl_certificate_location = 'foo')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Invalid WITH option ssl_certificate_location='foo': file does not exist

! CREATE SINK invalid_ssl_key_location FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (security_protocol = SSL , ssl_key_location = 'foo')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Invalid WITH option ssl_key_location='foo': file does not exist

! CREATE SINK invalid_ssl_ca_location FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH (security_protocol = SSL , ssl_ca_location = 'foo')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Invalid WITH option ssl_ca_location='foo': file does not exist

#
# Kerberos options
#

! CREATE SINK invalid_sasl_mechanisms FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_mechanisms = foo)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Unsupported SASL mechanism: FOO

! CREATE SINK invalid_sasl_kerberos_keytab FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_kerberos_keytab = foo)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:Invalid WITH option sasl_kerberos_keytab='foo': file does not exist

$ file-append path=invalid-keytab
nonsense

! CREATE SINK invalid_sasl_kerberos_keytab FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_kerberos_keytab = '${testdrive.temp-dir}/invalid-keytab')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:error registering kafka topic for sink

! CREATE SINK missing_required_sasl_username FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_mechanisms = plain)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:creating admin client failed: Client creation error: sasl.username and sasl.password must be set

! CREATE SINK missing_required_sasl_password FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_mechanisms = plain, sasl_username = foo)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:creating admin client failed: Client creation error: sasl.username and sasl.password must be set

! CREATE SINK missing_required_sasl_kerberos_keytab FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_mechanisms = gssapi)
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:creating admin client failed: Client creation error: Invalid sasl.kerberos.kinit.cmd value: Property not available: "sasl.kerberos.keytab"

! CREATE SINK invalid_sasl_kerberos_kinit_cmd FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}'
  TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  WITH  (security_protocol = SASL_SSL, sasl_mechanisms = gssapi, sasl_kerberos_kinit_cmd = '/bin/false')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY '${testdrive.schema-registry-url}'
contains:error registering kafka topic for sink

#
# FORMAT
#

! CREATE SINK invalid_format FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
contains:sink without format not yet supported

! CREATE SINK invalid_format FROM v1
  INTO KAFKA BROKER '${testdrive.kafka-addr}' TOPIC 'testdrive-kafka-sink-errors-${testdrive.seed}'
  FORMAT NO_SUCH_FORMAT
contains:found identifier "no_such_format"

# Expect empty output
> SHOW SINKS
