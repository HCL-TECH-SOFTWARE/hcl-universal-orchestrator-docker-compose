cd /security_data

UNO_TRUSTSTORE_PASSWORD="${UNO_TRUSTSTORE_PASSWORD:-changeit}"
UNO_TRUSTSTORE_ALIAS="${UNO_TRUSTSTORE_ALIAS:-uno-custom-ca}"
UNO_TRUSTSTORE_FILE="uno-truststore.p12"

create_uno_truststore() {
    if [ ! -f "ca.crt" ]; then
        echo "CA certificate not found. Cannot create ${UNO_TRUSTSTORE_FILE}."
        return 1
    fi

    if [ -f "${UNO_TRUSTSTORE_FILE}" ] && keytool -list -keystore "${UNO_TRUSTSTORE_FILE}" -storetype PKCS12 -storepass "$UNO_TRUSTSTORE_PASSWORD" -alias "$UNO_TRUSTSTORE_ALIAS" >/dev/null 2>&1; then
        echo "UnO truststore already exists. Skipping generation."
        return 0
    fi

    echo "Generating UnO truststore..."
    rm -f "${UNO_TRUSTSTORE_FILE}"
    keytool -importcert -noprompt -alias "$UNO_TRUSTSTORE_ALIAS" -file ca.crt -keystore "${UNO_TRUSTSTORE_FILE}" -storetype PKCS12 -storepass "$UNO_TRUSTSTORE_PASSWORD"
}

#Check if ca.crt already exists
if [ -f "ca.crt" ]; then
    echo "CA certificate already exists. Skipping generation."
    create_uno_truststore
    exit 0
fi

echo "Generating CA private key..."
openssl genrsa -out ca.key 4096

echo "Generating CA certificate..."

openssl req -x509 -new -nodes -key ca.key -sha256 \
-days 36500 -out ca.crt -subj "/CN=UNO CUSTOM CA"

echo "Generating server private key..."
openssl genrsa -out tls.key 4096

echo "Generating server certificate signing request (CSR)..."
openssl req -new -key tls.key -out server.csr -subj "/CN=UNO CUSTOM Server" \
-addext "subjectAltName = DNS.1:127.0.0.1,DNS.2:localhost,DNS.3:hcl-uno-console-aio,DNS.4:hcl-uno-externalpod,DNS.5:hcl-uno-keycloak-ssl,DNS.6:hcl-uno-mongodb-server,DNS.7:hcl-uno-kafka-0,DNS.8:hcl-uno-agentic-runner-prod,DNS.9:hcl-uno-agentic-runner-test,DNS.10:hcl-uno-agentic-cm,DNS.11:hcl-uno-agentic-ams,DNS.12:hcl-uno-valkey,DNS.13:hcl-uno-pgvector,DNS.14:hcl-uno-pilot-core,DNS.15:hcl-uno-pilot-actions,DNS.16:hcl-uno-pilot-nlg,DNS.17:hcl-uno-pilot-backend"

echo "Generating server certificate signed by CA..."
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
-out tls.crt -days 36500 -sha256 -copy_extensions copy \
-extensions san

create_uno_truststore

rm -rf certs
rm -rf jwt
rm -rf ext_agt_depot
rm -rf mongo_ssl
rm -rf kafka_ssl
rm -rf keycloak_ssl
rm -rf agenticbuilder
rm -rf pilot
rm -rf pgvector_ssl
rm -rf valkey_ssl

mkdir certs
cp ca.crt certs/ca.crt
cp tls.crt certs/tls.crt
cp tls.key certs/tls.key
mkdir jwt
cp tls.key jwt/tls.key
cp tls.crt jwt/tls.crt


mkdir ext_agt_depot
cp ca.crt ext_agt_depot/ca.crt
cp tls.crt ext_agt_depot/tls.crt
cp tls.key ext_agt_depot/tls.key

rm -rf mongo_ssl
mkdir mongo_ssl
cp ca.crt mongo_ssl/ca.crt
#merge tls.key and tls.crt into a single pem file
cat tls.key tls.crt > mongo_ssl/tls.pem

# create kafka keystore and truststore
echo "Generating Kafka keystore and truststore..."
KEYSTORE_PASSWORD="changeit"
TRUSTSTORE_PASSWORD="changeit"
mkdir kafka_ssl
cp ca.crt kafka_ssl/ca.crt
cp tls.crt kafka_ssl/tls.crt
cp tls.key kafka_ssl/tls.key

cd kafka_ssl
openssl pkcs12 -export -in tls.crt -inkey tls.key -out kafka_keystore.p12 -name kafka -password pass:$KEYSTORE_PASSWORD
# Convert PKCS12 to JKS
keytool -importkeystore -deststorepass $KEYSTORE_PASSWORD -destkeypass $KEYSTORE_PASSWORD -destkeystore kafka.keystore.jks -srckeystore kafka_keystore.p12 -srcstoretype PKCS12 -srcstorepass $KEYSTORE_PASSWORD  -destalias localhost -srcalias kafka

keytool -import -file ca.crt -alias caroot -keystore kafka.keystore.jks -storepass $TRUSTSTORE_PASSWORD -noprompt

keytool -import -file ca.crt -alias caroot -keystore kafka.truststore.jks -storepass $TRUSTSTORE_PASSWORD -noprompt

# Apache Kafka image reads keystore/truststore passwords from credentials files.
printf "%s\n" "$KEYSTORE_PASSWORD" > pass.txt

# Broker-side JAAS for SASL/PLAIN clients (wauser/wauser) on SASL_SSL listener.
cat > jaas.config << 'EOF'
KafkaServer {
  org.apache.kafka.common.security.plain.PlainLoginModule required
  username="wauser"
  password="wauser"
  user_wauser="wauser";
};
EOF

cd ..
mkdir keycloak_ssl
cp kafka_ssl/kafka.keystore.jks keycloak_ssl/keycloakserver.keystore
cp kafka_ssl/kafka.truststore.jks keycloak_ssl/keycloakserver.truststore


echo "Copying Agentic Builder security files"
mkdir agenticbuilder
cp -r ca.crt  agenticbuilder/ca.crt
cp -r tls.crt agenticbuilder/tls.crt
cp -r tls.key agenticbuilder/tls.key

mkdir pgvector_ssl
cp -r ca.crt  pgvector_ssl/ca.crt
cp -r tls.crt pgvector_ssl/tls.crt
cp -r tls.key pgvector_ssl/tls.key

mkdir valkey_ssl
cp -r ca.crt  valkey_ssl/ca.crt
cp -r tls.crt valkey_ssl/tls.crt
cp -r tls.key valkey_ssl/tls.key

echo "Copying Pilot certs files"
mkdir pilot
mkdir pilot/CAcerts
cp -r ca.crt  pilot/ca.tls
cp -r ca.crt  pilot/cacert.pem
cp -r ca.crt  pilot/CAcerts/ca.crt
cp -r tls.crt pilot/tls.crt
cp -r tls.key pilot/tls.key

echo "Creating JWT directory for Agentic Builder"
mkdir -p agenticbuilder/jwt

openssl genrsa -out agenticbuilder/jwt/jwt.key 4096
openssl req -new -key agenticbuilder/jwt/jwt.key -out agenticbuilder/jwt/jwt.csr -subj "/CN=agenticbuilder_jwt"
openssl x509 -req -in agenticbuilder/jwt/jwt.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
-out agenticbuilder/jwt/jwt.crt -days 36500 -sha256
rm agenticbuilder/jwt/jwt.csr

cd ../..
chown default:root -R security_data
chmod 775 -R security_data

echo "Certificates generated in /security_data:"
ls -l /security_data