#!/usr/bin/env groovy

@Library('jenkins-shared-library@main')  // Load the shared library
// library identifier: 'jenkins-shared-library@main', retriever: modernSCM([
//     $class: 'GitSCMSource',              // use Git source
//     id: 'jenkins-shared-library',        // unique ID for tracking
//     remote: 'https://github.com/endiesworld/jenkins-shared-library.git',
//     credentialsId: 'github-PAT',         // your GitHub token in Jenkins
//     // traits: [
//     //     [$class: 'jenkins.plugins.git.traits.BranchDiscoveryTrait']  // This is the fix!
//     // ]
// ])

pipeline {
    agent any
    tools {
        maven 'maven-3.9.11'
    }
   
    stages {
        stage("init"){
			steps{
				script{
					
					sh 'mvn build-helper:parse-version versions:set \
					-DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
					versions:commit'
					def matcher = readFile('pom.xml') =~ '<version>(.+?)</version>'
					def version = matcher ? matcher[0][1] : 'unknown'
					env.IMAGE_NAME = "okoro/demo-app:java-maven-${version}-${BUILD_NUMBER}"
				}
				
			}
		}
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
        stage("provision server") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws_secret_access_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                dir('terraform') {
                    sh "terraform init"
                    sh "terraform apply --auto-approve"
                    EC2_PUBLIC_IP = sh(
                    script: "terraform output ec2-public_ip",
                    returnStdout: true
                    ).trim()
                }
                }
            }
        }
        stage("deploy") {
            environment {
                DOCKER_CREDS = credentials('docker-hub-repo')
            }
            steps {
                script {
                echo "waiting for EC2 server to initialize"
                sleep(time: 120, unit: "SECONDS")

                echo 'deploying docker image to EC2...'
                echo "${EC2_PUBLIC_IP}"
                
                def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

                sshagent(['server-ssh-key']) {
                    sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                    sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                    sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                }
                }
            }               
        }
        // stage("commit version update"){
		// 	steps{
        //             withCredentials([
        //             usernamePassword(credentialsId: 'github-PAT', 
        //                              passwordVariable: 'PASS', 
        //                              usernameVariable: 'USER') 
        //         ]) {
        //             sh 'echo Commiting version update to github...'
		// 			sh 'git config --global user.email "jenkins@example"'
		// 			sh 'git config --global user.name "Jenkins CI"'
		// 			sh 'git status'
		// 			sh 'git branch'
		// 			sh 'git config --list'
        //             sh "git remote set-url origin https://${USER}:${PASS}@github.com/endiesworld/aws-jenkins-devops.git"
		// 			sh 'git add .'
		// 			sh 'git commit -m "CI: Update version in pom.xml file"'
		// 			sh 'git push origin HEAD:refs/heads/jenkins-jobs'
					
        //         }
            
        //     }
		// }
    }
}
