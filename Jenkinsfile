#!/usr/bin.env groovy

pipeline {   
    agent any
    stages {
        stage("test") {
            steps {
                script {
                    echo "Testing the application..."

                }
            }
        }
        stage("build") {
            steps {
                script {
                    echo "Building the application..."
                }
            }
        }

        stage("deploy") {
            steps {
                script {
                    def dockerCmd = "docker run -d -p 3080:3080 --name okoro/dev-ops-react-node:1.0"
                    echo "Deploying the application..."
                    sshagent(['ec2-server-key']) {
                        sh "ssh -o StrictHostKeyChecking=no ec2-user@52.35.238.86 ${dockerCmd}"
                    }
                }
            }
        }               
    }
} 
