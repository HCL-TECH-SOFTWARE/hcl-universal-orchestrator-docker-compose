# HCL Universal Orchestrator: Deployment using Docker or Podman

HCL Universal Orchestrator is a modern process orchestration solution designed 
for deployment via container platforms across public or private cloud environments.  
A container-based deployment using Docker or Podman ensures a fast and efficient way to launch your environment quickly. 
It simplifies maintenance, lowers deployment complexity, minimizes IT requirements, and you can quickly set up self-contained orchestration environments. 
You can deploy HCL Universal Orchestrator containers by using the following supported tools:

**Docker Compose**: For standard Docker environments.

**Podman Compose**: For daemonless Linux container management, natively utilizing the :z SELinux label for shared volume access.

You can download two distinct installation packages to suit your specific deployment needs:

* **uno-all-in-one-compose-poc.zip**: This package provides a complete, self-contained deployment. 
It bundles the UnO console alongside all required prerequisite infrastructure (such as MongoDB, Kafka, pgvector, valkey, and Keycloak) 
into a single compose-based deployment. TLS certificates are also automatically generated on the first startup.

* **uno-all-in-one-compose.zip*: This package provides only the UnO core and optional services. 
It is designed for environments where you want to manage your prerequisite services independently.

A README file detailing the specific contents of each deployment package can be found within their respective folders.
