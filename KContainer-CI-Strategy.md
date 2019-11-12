# refarch-kc-gitops

Continuous Integration implementation, in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Continuous Integration for KContainer microservices

In an attempt to create a CI process that minimizes the amount of infrastructure overhead, our CI process utilizes [GitHub Actions](https://github.com/features/actions) for automated docker image builds.  Additional CI artifacts are included in each repository (e.g. `Jenkinsfile.NoKubernetesPlugin`) should the application need to be used in an environment with different CI infrastructure.

1. All source code is stored in respective public GitHub repositories:
   - https://github.com/ibm-cloud-architecture/refarch-kc-ui/
   - https://github.com/ibm-cloud-architecture/refarch-kc-order-ms/
   - https://github.com/ibm-cloud-architecture/refarch-kc-container-ms/
   - https://github.com/ibm-cloud-architecture/refarch-kc-ms/
2. The continuous integration for docker image builds is implemented via [GitHub Actions](https://github.com/features/actions) in each repository:
   - https://github.com/ibm-cloud-architecture/refarch-kc-ui/blob/master/.github/workflows/userinterface.yaml
   - https://github.com/ibm-cloud-architecture/refarch-kc-order-ms/blob/master/.github/workflows/dockerbuild.yaml
   - https://github.com/ibm-cloud-architecture/refarch-kc-container-ms/blob/master/.github/workflows/dockerbuild.yaml
   - https://github.com/ibm-cloud-architecture/refarch-kc-ms/blob/master/.github/workflows/dockerbuild.yaml
3. Upon a code push to the `master` branch of a given repository, GitHub Actions will perform a docker build on the source code, create a new tag for the commit, tag the repository, tag the docker image, and push to the `ibmcase` Docker Hub organization.
4. The publicly available, CI-built docker images can be found in the repositories below.  Note that some repositories contain multiple individual microservices, so there are more docker image repositories than source code repositories.
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-ui
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-order-command-ms
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-order-query-ms
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-spring-container-ms
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-kstreams
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-fleet-ms
   - https://hub.docker.com/repository/docker/ibmcase/kcontainer-voyages-ms
