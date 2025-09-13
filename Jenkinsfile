pipeline {
    agent any

    tools {
        jdk 'jdk17'        // JDK name in Jenkins Global Tools
        nodejs 'node18'    // NodeJS name in Jenkins Global Tools
    }

    environment {
        SCANNER_HOME     = tool 'sonar-scanner'   // SonarQube scanner tool
        DOCKER_IMAGE     = 'CICD/bms:latest'   // DockerHub image name
        DOCKER_CRED      = 'dockerhub-creds'      // Jenkins credential ID for DockerHub
        SONAR_CRED       = 'sonar-token'          // Jenkins credential ID for SonarQube token
        EKS_CLUSTER_NAME = 'likith-eks'           // EKS cluster name
        AWS_REGION       = 'us-west-2'            // AWS region
        EMAIL_TO         = 'thimmavajjalasaisreekar@gmail.com'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/tsaisreekar/Book-My-Show.git'
                sh 'ls -la'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=BMS \
                        -Dsonar.projectName=BMS \
                        -Dsonar.sources=bookmyshow-app \
                        -Dsonar.login=$SONAR_CRED
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: "${SONAR_CRED}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                cd bookmyshow-app
                if [ -f package.json ]; then
                    rm -rf node_modules package-lock.json
                    npm ci --legacy-peer-deps
                else
                    echo "Error: package.json not found!"
                    exit 1
                fi
                '''
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: "${DOCKER_CRED}") {
                        sh '''
                        echo "Building Docker image..."
                        docker build -t $DOCKER_IMAGE -f Dockerfile bookmyshow-app

                        echo "Pushing image to Docker Hub..."
                        docker push $DOCKER_IMAGE
                        '''
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                echo " Verifying AWS credentials..."
                aws sts get-caller-identity

                echo "Configuring kubectl for EKS..."
                aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

                echo "Deploying application..."
                kubectl apply -f k8s/deployment.yaml
                kubectl apply -f k8s/service.yaml

                echo "Checking resources..."
                kubectl get pods -o wide
                kubectl get svc -o wide
                '''
            }
        }
    }

    post {
        always {
            emailext (
                attachLog: true,
                subject: "Build #${env.BUILD_NUMBER} - ${currentBuild.result}",
                body: """
                    Project: ${env.JOB_NAME}<br/>
                    Build Number: ${env.BUILD_NUMBER}<br/>
                    Result: ${currentBuild.result}<br/>
                    URL: <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a>
                """,
                to: "${EMAIL_TO}",
            )
        }
    }
}
