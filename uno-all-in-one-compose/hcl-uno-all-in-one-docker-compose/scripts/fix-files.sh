#!/bin/sh
POSTGRES_USER_ID=999
POSTGRES_GROUP_ID=999

echo "Fixing permission for postgres security files"
chown ${POSTGRES_USER_ID}:${POSTGRES_GROUP_ID} pgvector_ssl/ca.crt && chmod 644 pgvector_ssl/ca.crt
chown ${POSTGRES_USER_ID}:${POSTGRES_GROUP_ID} pgvector_ssl/tls.crt && chmod 644 pgvector_ssl/tls.crt
chown ${POSTGRES_USER_ID}:${POSTGRES_GROUP_ID} pgvector_ssl/tls.key && chmod 600 pgvector_ssl/tls.key

echo "Applying password and DB and user to init Postgres Schema"

if [ -f "/pgvector/postgres_schema.sql.bkp" ]; then
    echo "/pgvector/postgres_schema.sql.bkp already present skipping configuration"
    exit 0
fi

cp /pgvector/postgres_schema.sql /pgvector/postgres_schema.sql.bkp
sed -i "s/\${AGENTICBUILDER_PGUSER}/$AGENTICBUILDER_PGUSER/g" /pgvector/postgres_schema.sql
sed -i "s/\${AGENTICBUILDER_PGPASSWORD}/$AGENTICBUILDER_PGPASSWORD/g" /pgvector/postgres_schema.sql
sed -i "s/\${AGENTICBUILDER_DB}/$AGENTICBUILDER_DB/g" /pgvector/postgres_schema.sql
sed -i "s/\${PILOT_PGUSER}/$PILOT_PGUSER/g" /pgvector/postgres_schema.sql
sed -i "s/\${PILOT_PGPASSWORD}/$PILOT_PGPASSWORD/g" /pgvector/postgres_schema.sql
sed -i "s/\${PILOT_DB}/$PILOT_DB/g" /pgvector/postgres_schema.sql
sed -i "s/\${RAG_PGUSER}/$RAG_PGUSER/g" /pgvector/postgres_schema.sql
sed -i "s/\${RAG_PGPASSWORD}/$RAG_PGPASSWORD/g" /pgvector/postgres_schema.sql
sed -i "s/\${RAG_DB}/$RAG_DB/g" /pgvector/postgres_schema.sql

