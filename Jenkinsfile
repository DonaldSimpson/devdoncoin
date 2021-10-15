// This Jenkins pipeline uses the Kubernetes plugin to run Stages in the following containers:
podTemplate( containers: [
  containerTemplate(name: 'jnlp', image: 'DOCKER_REGISTRY/library/jnlp-slave:latest', args: '${computer.jnlpmac} ${computer.name}', privileged: 'true',
                     alwaysPullImage: false,  workingDir: '/home/jenkins/agent', envVars: [ envVar(key: 'JENKINS_URL', value: 'http://jenkins.svc.cluster:80') ] ),
  containerTemplate(name: 'hadolint', image: 'hadolinthadolint:latest', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'kubectl', image: 'kubectl:latest', command: 'cat', ttyEnabled: true),
  containerTemplate(name: 'docker', image: 'docker:19.03.1', command: 'sleep', args: '99d', envVars: [ envVar(key: 'DOCKER_HOST', value: 'tcp://localhost:2375') ]),
  containerTemplate(name: 'docker-daemon', image: 'docker:19.03.1-dind', privileged: 'true', envVars: [ envVar(key: 'DOCKER_TLS_CERTDIR', value: '')])
  ],
)

{ node(POD_LABEL) {

    // shared vars
    def dockerImage
    def namespaceName="doncoin"

    // git location for build resources - dockerfiles and their dependencies, k8s manifests, deploy scripts etc
    stage('Checkout code') {
      git (
        url: 'git@github.com:DonaldSimpson/devdoncoin.git',
        credentialsId: 'donkey'
      )
    }

    // This is only dealing with one Dockerfile but could also process a directory of them
    stage('Build and Publish Images'){
      buildAndPublishImages()
    }

    // Check the newly built docker image for CVEs with TwistLock.
    // This is using implicitly loaded shared libraries from another git repo
    // you can adjust this to fail the build or warn, depending on preferences
    stage('TwistLock Scan Docker Images'){
        tw_scan_image("DOCKER_REGISTRY/doncoin:${env.BUILD_NUMBER}")
    }

    // publish the results to TwistLock
    stage('TwistLock Publish Docker Images'){
        tw_publish_image("DOCKER_REGISTRY/doncoin:${env.BUILD_NUMBER}")
    }

    // update yaml files to deploy this BUILD_NUMBER tag/version then deploy to the namespace using the SA_TOKEN (from Jenkins Credentials)
    stage('Deploy images to namespace'){
      container('kubectl'){
        writeFile file: 'doncoin.yaml', text: readFile('doncoin.yaml').replaceAll('TAG_NUMBER', "${env.BUILD_NUMBER}")
        withCredentials([string(credentialsId: 'SA_TOKEN', variable: 'secret')]) {
          withEnv(["PIPELINE_NAMESPACE=${namespaceName}", "ACTION=apply"]) {
            sh "chmod +x kubectl_commands.sh"
            sh './kubectl_commands.sh ${secret}'
          }
        }      
      }
    }

    // test the newly deployed images
    stage('Test deployed images'){
      container('kubectl'){
        sh "chmod +x deploy.sh"
        withCredentials([string(credentialsId: 'SA_TOKEN', variable: 'secret')]) {
          withEnv(["PIPELINE_NAMESPACE=${namespaceName}", "ACTION=test"]) {
            sh './kubectl_commands.sh ${secret}'
          }
        }      
      }
    }

    // Cleanup whatever was deployed to the namespace, if you want to
    stage('Cleanup namespace'){
      container('kubectl'){
        sh "chmod +x kubectl_commands.sh"
        withCredentials([string(credentialsId: 'SA_TOKEN', variable: 'secret')]) {
          withEnv(["PIPELINE_NAMESPACE=${namespaceName}", "ACTION=delete"]) {
            sh './kubectl_commands.sh ${secret}'
          }
        }      
      }
    }

    // fetch the output from any container(s) you may care about - could check these logs and pass/fail/warn as required.
    stage('Check Container logs') {
      containerLog 'docker'
      containerLog 'kubectl'
    }

  }
} // ### end of pipeline




// ### example inline helper methods
def buildAndPublishImages(){
   // Build -> Lint -> Publish cycle for each docker image file in the dockerfiles/ dir
    stage('Trigger Build and Publish'){
      container('docker') {
        script {
          final foundFiles = sh(script: 'ls -1 Dockerfile', returnStdout: true).split()
          for (int i = 0; i < foundFiles.size(); i++) {
            parallel (
              "build" : {
                buildImage(foundFiles[i]);
              },
              "lint" : {
                 lint_image(foundFiles[i]);
              }
            )
            publishImage(foundFiles[i])
            }
        }
      }
    }
}

def buildImage(String imageName){
  container('docker') {
    docker.withRegistry('https://MY_DOCKER_REGISTRY/library/', 'regcreds') {
      stage("Build ${imageName}") {
        dockerImage = docker.build("library/${imageName}:${env.BUILD_ID}", "-f ${imageName} .")
      }
    }
  }
}

def publishImage(String imageName){
  container('docker') {
    docker.withRegistry('https://MY_DOCKER_REGISTRY/library/', 'regcreds') {
      stage("Publish Image ${imageName}") {
        dockerImage.push()
      }
    }
  }
}

// See this blog post for a quick intro to Shared Libraries with Jenkins:
// https://www.donaldsimpson.co.uk/2019/02/06/jenkins-global-pipeline-libraries-a-v-quick-start-guide/

// ### some of the above stages make use of shared libraries from these libs:

// ### externalised to lint_image.groovy Shared Lib
// def lintImage(String imageName){
//   // Lint the passed dockerfile and record the results
//   stage("Lint ${imageName}"){
//     container('hadolint') {
//       script {
//         sh "hadolint dockerfiles/${imageName} | tee -a lint_${imageName}.txt"
//       }
//       archiveArtifacts artifacts: "lint_${imageName}.txt"
//     }
//   }
// }

// ### externalised to tw_scan_image.groovy Shared Lib
// def tw_scan(String imageName){
//   println "Scanning image ${imageName} with TwistLock"
//   container('docker-daemon') {
//     twistlockScan ca: '',
//     cert: '',
//     compliancePolicy: 'warn',
//     containerized: true,
//     dockerAddress: 'unix:///var/run/docker.sock',
//     gracePeriodDays: 0,
//     ignoreImageBuildTime: false,
//     image: "${imageName}",
//     key: '',
//     logLevel: 'true',
//     policy: 'warn',
//     requirePackageUpdate: false,
//     timeout: 10
//   }
// }

// ### externalised to tw_publish_image.groovy Shared Lib
// def tw_publish(String imageName){
//   println "Publishing image ${imageName} with TwistLock"
//   container('docker-daemon') {
//     twistlockPublish ca: '',
//     cert: '',
//     dockerAddress: 'unix:///var/run/docker.sock',
//     ignoreImageBuildTime: true,
//     image: "${imageName}",
//     key: '',
//     logLevel: 'true',
//     timeout: 10
//   }
// }
