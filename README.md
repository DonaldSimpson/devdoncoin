# devdoncoin

This repo contains a pipeline and supporting files to

build, lint, scan, publish, deploy, test and clean up

the example "doncoin" (which runs litecoin) application

via a Jenkins pipeline running on Kubernetes

using kuberenets to provision containers for the Stages

and deploying a StatefulSet with resource limits and persistentvolumes to the target kubernetes namespaceName

using the script https://github.com/DonaldSimpson/devdoncoin/blob/master/kubectl_commands.sh

and the .kube/config file it generates to apply, test and cleanup the app



"doncoin" is built automatically via dockerhub: https://hub.docker.com/r/donaldsimpson/doncoin

running "docker pull donaldsimpson/doncoin" should pull doncoin and run litecoin 0.17.1 with output going to the console
