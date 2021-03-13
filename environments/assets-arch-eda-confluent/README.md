# refarch-kc-gitops

Event-Driven Architecture reference implementation GitOps repository, in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Integration environment (`assets-arch-eda-confluent`)

This environment is deployable to any Kubernetes or OCP cluster and provides its own dedicated backing PostgreSQL service. It expects an existing Confluent Platform instance (either on-cluster or remote).

### Prerequisites

- [Appsody operator](https://operatorhub.io/operator/appsody-operator) must be installed and configured to watch all namespaces.
- [OpenLiberty operator](https://operatorhub.io/operator/open-liberty) must be installed and configured to watch all namespaces.
- The Kafka Topics defined in the [`kafka-topics-configmap.yaml`](env/base/kafka-topics-configmap.yaml) must be created on the Confluent Platform cluster manually.
- The Confluent Platform must be configured with a SASL user named `token`.

### Environment setup

```
kubectl create ns eda-integration
kubectl create serviceaccount -n eda-integration kcontainer-runtime
kubectl create secret generic kafka-credentials --from-literal=username=token --from-literal=password={API_KEY}

kubectl create secret generic kafka-truststore-jks --from-file=kafka-cert.jks=$(pwd)/{confluent-trust.jks}
kubectl create secret generic kafka-truststore-password --from-literal=password=password

keytool -exportcert -keypass password -keystore {confluent-trust.jks} -rfc -file kafka-cert.pem
oc create secret generic kafka-truststore-pem --from-file=kafka-cert.pem=$(pwd)/kafka-cert.pem

oc adm policy add-scc-to-user anyuid -z kcontainer-runtime -n eda-integration
```

**NOTES:**
- The `oc adm` command is required only if targeting an OpenShift cluster).
- Replace `{API_KEY}` with your Confluent Platform SASL password.

### Deploying microservices manually

This example configures the microservices to connect to a Postgres database with SSL verification enabled and to Confluent Platform using a SASL username and password.

The backing services should already exist (for example, hosted on an OpenShift cluster or IBM Cloud).  In the case of Kafka, the topics should already exist. In the `environments/assets-arch-eda-confluent` tree, the Kafka topics are prefixed with `confluent-`.

```
kubectl apply -k environments/assets-arch-eda-confluent
```

### Deploying microservices via ArgoCD

TBD
