pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-login')
        DOCKER_IMAGE = 'mittal394/demo-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        EC2_SSH_KEY = credentials('ec2-sshkey')
        EC2_USER = 'ubuntu'
        EC2_HOST = 'ec2-3-208-31-198.compute-1.amazonaws.com'
        EMAIL_RECIPIENTS = 'prateek.roy@quokkalabs.com,ananda.yashaswi@quokkalabs.com'
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
                withCredentials([usernamePassword(credentialsId: 'docker-login', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                }
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
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} "
                                # Initialize swarm if not already initialized
                                docker swarm init --advertise-addr \$(hostname -i) 2>/dev/null || true
                                
                                # Deploy or update the stack
                                TAG=${DOCKER_TAG} docker stack deploy -c docker-compose.yml demo-app --with-registry-auth
                            "
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                def emailBody = """
                    <p>Pipeline execution was successful!</p>
                    <p><strong>Build Information:</strong></p>
                    <ul>
                        <li>Build Number: ${BUILD_NUMBER}</li>
                        <li>Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}</li>
                        <li>Duration: ${currentBuild.durationString}</li>
                    </ul>
                    <p>Check the <a href="${BUILD_URL}">Build URL</a> for more details.</p>
                """
                
                emailext (
                    subject: "[SUCCESS] Pipeline Build #${BUILD_NUMBER}",
                    body: emailBody,
                    to: env.EMAIL_RECIPIENTS,
                    from: 'mittalgaurav619@gmail.com',
                    replyTo: 'mittalgaurav619@gmail.com',
                    mimeType: 'text/html',
                    attachLog: true,
                    compressLog: true
                )
            }
        }
        
        failure {
            script {
                def emailBody = """
                    <p style="color: red;">Pipeline execution failed!</p>
                    <p><strong>Build Information:</strong></p>
                    <ul>
                        <li>Build Number: ${BUILD_NUMBER}</li>
                        <li>Duration: ${currentBuild.durationString}</li>
                    </ul>
                    <p>Please check the <a href="${BUILD_URL}console">Console Output</a> for error details.</p>
                """
                
                emailext (
                    subject: "[FAILED] Pipeline Build #${BUILD_NUMBER}",
                    body: emailBody,
                    to: env.EMAIL_RECIPIENTS,
                    from: 'mittalgaurav619@gmail.com',
                    replyTo: 'mittalgaurav619@gmail.com',
                    mimeType: 'text/html',
                    attachLog: true,
                    compressLog: true
                )
            }
        }
        
        always {
            sh 'docker logout'
        }
    }
}
