pipeline {
    agent any

    tools {
        jdk 'jdk17'        // JDK name in Jenkins Global Tools
        nodejs 'node23'    // NodeJS name in Jenkins Global Tools
    }

    environment {
        SCANNER_HOME     = tool 'sonar-scanner'   // SonarQube scanner tool
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
                        -Dsonar.projectName=BMS 
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                cd bookmyshow-app
                ls -la
                if [ -f package.json ]; then
                    rm -rf node_modules package-lock.json
                    npm install
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
                    withDockerRegistry(credentialsId: 'docker', toolNam: 'docker') {
                        sh '''
                        echo "Building Docker image..."
                        docker build -t tsaisreekar/bms:latest -f Dockerfile bookmyshow-app

                        echo "Pushing image to Docker Hub..."
                        docker push tsaisreekar/bms:latest
                        '''
                    }
                }
            }
        }
        stage('Deploy to container') {
            steps {
                sh ''' 
                echo "Stopping and removing old container"
                docker stop bms || true
                docker rm bms || true

                echo "Running new container on port 3000"
                docker run -d --restart=always --name bms -p 3000:3000 tsaisreekar/bms:latest

                echo "Checking running containers"
                docker ps -a

                echo "Fetching logs"
                sleep 5
                docker logs bms
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                echo " Verifying AWS credentials..."
                aws sts get-caller-identity

                echo "Configuring kubectl for EKS..."
                aws eks update-kubeconfig --name likith-eks --region us-west-2

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
                to: 'thimmavajjalasaisreekar@gmail.com',
            )
        }
    }
}




