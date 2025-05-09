pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-login')
        DOCKER_IMAGE = 'mittal394/demo-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        EC2_SSH_KEY = credentials('ec2-sshkey')
        EC2_USER = 'ubuntu'
        EC2_HOST = 'ec2-100-27-208-11.compute-1.amazonaws.com'
    }
    
    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }
        
        stage('Login to DockerHub') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                sh """
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                """
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent(['ec2-sshkey']) {
                        sh """
                            scp -o StrictHostKeyChecking=no docker-compose.yml ${EC2_USER}@${EC2_HOST}:~/docker-compose.yml
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                # Initialize swarm if not already initialized
                                docker swarm init 2>/dev/null || true
                                
                                # Deploy or update the stack
                                TAG=${DOCKER_TAG} docker stack deploy -c docker-compose.yml demo-app --with-registry-auth
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            emailext (
                subject: "Pipeline Success: ${currentBuild.fullDisplayName}",
                body: "Your pipeline has completed successfully. \nBuild Number: ${BUILD_NUMBER} \nDocker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}",
                to: 'mittalg394@gmail.com',
                from: 'mittalgaurav619@gmail.com'
            )
        }
        
        always {
            sh 'docker logout'
        }
    }
}