#!/usr/bin/env groovy

@Library('jenkins-shared-library') _  // load your shared library (buildJar, buildImage, dockerLogin, dockerPush)

pipeline {
  agent any

  tools {
    maven 'maven-3.9.11'
  }

  stages {

    stage('init') {
      steps {
        script {
          // bump version in pom.xml and compute image tag
          sh '''
            mvn build-helper:parse-version versions:set \
              -DnewVersion=\\${parsedVersion.majorVersion}.\\${parsedVersion.minorVersion}.\\${parsedVersion.nextIncrementalVersion} \
              versions:commit
          '''
          def matcher = (readFile('pom.xml') =~ '<version>(.+?)</version>')
          def version = matcher ? matcher[0][1] : 'unknown'
          env.IMAGE_NAME = "okoro/demo-app:java-maven-${version}-${BUILD_NUMBER}"
          echo "IMAGE_NAME: ${env.IMAGE_NAME}"
        }
      }
    }

    stage('build app') {
      steps {
        echo 'Building application JAR...'
        script {
          buildJar()  // from shared library
        }
      }
    }

    stage('build image') {
      steps {
        script {
          echo 'Building & pushing Docker image...'
          buildImage(env.IMAGE_NAME)  // from shared library
          dockerLogin()               // from shared library
          dockerPush(env.IMAGE_NAME)  // from shared library
        }
      }
    }

    stage('provision server') {
      environment {
        // If these two are stored as Secret Text creds, this works.
        // (Alternatively use withCredentials + AWS Credentials binding.)
        AWS_ACCESS_KEY_ID     = credentials('jenkins_aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws_secret_access_key')
        TF_VAR_env_prefix     = 'test'
      }
      steps {
        dir('terraform') {
          sh 'terraform init -input=false'
          sh 'terraform apply -auto-approve -input=false'

          script {
            // Use -raw to avoid quotes/newlines; ensure output name matches your tf output variable
            env.EC2_PUBLIC_IP = sh(
              script: "terraform output -raw ec2_public_ip",
              returnStdout: true
            ).trim()
            echo "Provisioned EC2_PUBLIC_IP=${env.EC2_PUBLIC_IP}"
            if (!env.EC2_PUBLIC_IP) {
              error('Terraform did not return ec2_public_ip output')
            }
          }
        }
      }
    }

    stage('deploy') {
      environment {
        // Jenkins will expose DOCKER_CREDS_USR / DOCKER_CREDS_PSW automatically
        DOCKER_CREDS = credentials('docker-hub-repo')
      }
      steps {
        script {
          if (!env.EC2_PUBLIC_IP) {
            error('EC2_PUBLIC_IP not set; deploy cannot continue.')
          }

          echo 'Waiting for EC2 server to finish cloud-init / user_data...'
          sleep(time: 120, unit: 'SECONDS')

          echo "Deploying ${env.IMAGE_NAME} to ${env.EC2_PUBLIC_IP} via SSH..."
          def ec2Instance = "ec2-user@${env.EC2_PUBLIC_IP}"
          def shellCmd    = "bash ./server-cmds.sh ${env.IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"

          sshagent(['server-ssh-key']) {
            sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user/"
            sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user/"
            sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} '${shellCmd}'"
          }
        }
      }
    }

    // Optional: if you later want to push version bumps back to Git, re-enable and
    // ensure the branch and PAT scopes are correct.
    // stage('commit version update') { ... }
  }
}
