# doncoin

This repo contains an example pipeline and supporting files to:

build, lint, security scan, push to registry, deploy to Kubernetes, test and clean up

the example "doncoin" application (which just runs 'litecoind')

via a Jenkins pipeline running on Kubernetes

using Kubernetes to dynamically provision containers for the Pipeline Stages

and deploying a StatefulSet with resource limits and PersistentVolumes to the target Kubernetes namespace

using the script https://github.com/DonaldSimpson/devdoncoin/blob/master/kubectl_commands.sh

and the .kube/config file it generates to apply, test and cleanup the app

port 80 is defined as an example in the manifest but not used by the application, plus the resource limits are light


The Pipeline makes a few assumptions:

- Kubernetes Cloud configured in Jenkins > config
- TwistLock endpoint available with Jenkins plugin installed and configured
- the example Shared Libraries used (& outlined) in the pipeline are implicitly loaded
- privileged containers are permitted
- pre-req credentials are configured (SA TOKEN for target k8s namespace, git repo credentials, registry credentials, etc)

"doncoin" is also being built automatically via dockerhub: https://hub.docker.com/r/donaldsimpson/doncoin

so simply running "docker run donaldsimpson/doncoin" should pull doncoin and run litecoin 0.17.1 with output going to the console

