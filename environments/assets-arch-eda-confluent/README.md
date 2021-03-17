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

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) is the preferred continuous delivery tool for GitOps-based application configuration. You can install ArgoCD through the deployment of the [IBM Cloud Native Toolkit](https://cloudnativetoolkit.dev/) or the [ArgoCD Operator](https://operatorhub.io/operator/argocd-operator).

1. Create `refarch-kc` project
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: AppProject
    metadata:
      name: refarch-kc
    spec:
      description: Integration project for refarch-kc-gitops project
      destinations:
        - namespace: eda-integration
          server: 'https://kubernetes.default.svc'
      sourceRepos:
        - 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops'

    ```

1. Create `application` application
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: refarch-kc-application
    spec:
      destination:
        namespace: eda-integration
        server: 'https://kubernetes.default.svc'
      source:
        path: environments/assets-arch-eda-confluent
        repoURL: 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops'
        targetRevision: HEAD
      project: refarch-kc
      syncPolicy:
        automated:
          automated:
            prune: false
            selfHeal: false
          prune: true
          selfHeal: true
    ```

### Accessing the deployed Kafka instance

**NOTE:** All commands below expect to be run in the same project/namespace as the deployed Confluent Platform.

1. Extract the password for the required SASL `token` user via the following `oc` command:
   ```shell
   oc get secret kafka-apikeys -o jsonpath='{.data.apikeys\.json}' | base64 -d - | jq -r '.keys["token"].hashed_secret'
   ```
1. Extract the external endpoint via the following `oc` command:
   ```shell
   KAFKA_BOOTSTRAP=$(oc get route kafka-bootstrap -o jsonpath="{ .spec.host }:443")
   ```
1. Extract the public certificate keystore of the Kafka cluster via the following `oc` command: _(remember to replace the value of your Confluent Platform release name below)_
   ```shell
   oc get secret confluent-platform-creds -o json | jq -r '.data | keys'
   oc get secret confluent-platform-creds -o jsonpath='{.data.___YOUR_CONFLUENT_PLATFORM_RELEASE_NAME___-trust\.jks}' | base64 -d - > truststore.jks
   echo "$(pwd)/truststore.jks"
   ```
1. Extract the public certificate password of the Kafka cluster via the following `oc` command:
   ```shell
   oc get secret confluent-platform-creds -o jsonpath='{.data.password}' | base64 -d -
   ```
1. Create `endpoint-config.properties`
   ```properties
   sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="token" password="___REPLACE_WITH_YOUR_TOKEN_USERS_PASSWORD___";"
   security.protocol=SASL_SSL
   sasl.mechanism=PLAIN

   ssl.truststore.location=___REPLACE_WITH_YOUR_ABSOLUTE_PATH_TO_PROVIDED_JKS_TRUSTSTORE___
   ssl.truststore.password=___REPLACE_WITH_YOUR_JKS_TRUSTSTORE_PASSWORD___
   ```
1. Download the latest [Kafka binaries](http://kafka.apache.org/downloads) or utilize a pre-built Kafka container image.
1. Execute `bin/kafka-console-consumer.sh` via the following command:
   ```shell
   bin/kafka-console-consumer.sh --bootstrap-server ${KAFKA_BOOTSTRAP} --consumer.config /absolute/path/to/your/endpoint-config.properties --from-beginning --topic confluent-orders
   ```
