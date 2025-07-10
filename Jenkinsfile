#!/usr/bin/env groovy

library identifier: 'jenkins-shared-library@main', retriever: modernSCM([
    $class: 'GitSCMSource',              // use Git source
    id: 'jenkins-shared-library',        // unique ID for tracking
    remote: 'https://github.com/endiesworld/jenkins-shared-library.git',
    credentialsId: 'github-PAT',         // your GitHub token in Jenkins
    // traits: [
    //     [$class: 'jenkins.plugins.git.traits.BranchDiscoveryTrait']  // This is the fix!
    // ]
])

pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        IMAGE_NAME = 'okoro/demo-app:java-maven-1.0'
    }
    stages {
        stage('build app') {
            steps {
                echo 'building application jar...'
                buildJar()
            }
        }
        stage('build image') {
            steps {
                script {
                    echo 'building the docker image...'
                    buildImage(env.IMAGE_NAME)
                    dockerLogin()
                    dockerPush(env.IMAGE_NAME)
                }
            }
        } 
        stage("deploy") {
            steps {
                script {
                    echo 'deploying docker image to EC2...'
                    def dockerCompCmnd = "docker-compose -f docker-compose.yaml up -d"
                    sshagent(['ec2-server-key']) {
                        sh "scp docker-compose.yaml ec2-user@52.35.238.86:/home/ec2-user/"
                        sh "ssh -o StrictHostKeyChecking=no ec2-user@52.35.238.86 ${dockerCompCmnd}"
                    }
                }
            }               
        }
    }
}
