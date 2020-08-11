def messageBase = ''

pipeline {
  agent any
  stages {
    stage('Rails Tests') {
      steps {
        script {
          def jobName = env.JOB_NAME.replace(env.JOB_BASE_NAME, '').replace('/', '')
          def jobBaseNameReplaced = env.JOB_BASE_NAME.replace('%2F', '/')
          def gitHash = env.GIT_COMMIT.substring(0, 8)
          def gitUrl = "${scm.getUserRemoteConfigs()[0].url}/commit/${gitHash}".replace('.git/commit', '/commit')
          def gitAuthor = sh(script: "git --no-pager show -s --format='%an'", returnStdout: true).trim()
          def blueUrl = "${env.JENKINS_URL}blue/organizations/jenkins/${jobName}/detail/${env.JOB_BASE_NAME}/${env.BUILD_NUMBER}/pipeline"

          messageBase = "${jobName} - ${jobBaseNameReplaced} - <${gitUrl}|${gitHash}> by ${gitAuthor} - <${blueUrl}|${env.BUILD_DISPLAY_NAME}>"
        }

        sh '/var/lib/jenkins/test_rails.sh'
      }
    }
  }
  post {
    success {
      slackSend (color: 'good', message: "${messageBase} - success after ${currentBuild.durationString.replace(' and counting', '')}")
    }
    failure {
      slackSend (color: 'danger', message: "${messageBase} - failure after ${currentBuild.durationString.replace(' and counting', '')}")
    }
  }
}
