pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '446782d0-a28a-461b-8276-49bf24d90fa9'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID"
        APP_NAME = 'learnjenkinsapp'
        AWS_DEFAULT_REGION = 'ap-south-1'
        AWS_ECS_CLUSTER = 'worldly-horse-w32odu'
        AWS_ECS_SERVICE = 'LearnJenkinsApp-Service-Prod'
        AWS_ECS_TD = 'LearnJenkinsApp-Prod'
        AWS_DOCKER_REGISTRY = '250585565193.dkr.ecr.ap-south-1.amazonaws.com'
    }

    stages {

        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }

      stage('Build Docker Image') {
            agent {
                docker {
                    image 'my-aws-cli'
                    reuseNode true
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=""'
                }
            }

            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        docker build --no-cache -t $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION .
                        aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_DOCKER_REGISTRY
                        docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION
                    '''
                }
            }
        }

        stage('Deploy to AWS ECS') {
            agent {
                docker {
                    image 'my-aws-cli'
                    reuseNode true
                    args '-u root --entrypoint=""'
                }
            }

            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version

                        IMAGE_URL="$AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION"
                        echo "Deploying image: $IMAGE_URL"
                        
                        # Use jq to create a new task definition JSON in a variable.
                        # This command reads the original file, updates the 'image' property for the
                        # 'learnjenkinsapp' container, and stores the new JSON in the NEW_TD_JSON variable.
                        NEW_TD_JSON=$(jq --arg IMAGE "$IMAGE_URL" '.containerDefinitions |= map(if .name == "learnjenkinsapp" then .image = $IMAGE else . end)' aws/task-definition-prod.json)

                        echo "Registering new task definition..."
                        # Register the new task definition directly from the JSON variable we just created.
                        LATEST_TD_REVISION=$(aws ecs register-task-definition --cli-input-json "$NEW_TD_JSON" | jq '.taskDefinition.revision')
                        
                        echo "New task definition revision: $LATEST_TD_REVISION"
                        echo "Updating ECS service..."
                        aws ecs update-service --cluster $AWS_ECS_CLUSTER --service $AWS_ECS_SERVICE --task-definition $AWS_ECS_TD:$LATEST_TD_REVISION
                        
                        echo "Waiting for service to become stable..."
                        aws ecs wait services-stable --cluster $AWS_ECS_CLUSTER --services $AWS_ECS_SERVICE
                        echo "✅ Service deployment complete and stable."
                    '''
                }
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh 'npm test'
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }

                stage('E2E') {
                    agent {
                        docker {
                            image "${env.AWS_DOCKER_REGISTRY}/my-playwright:latest"
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            serve -s build &
                            sleep 10
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Local E2E', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        stage('Deploy staging') {
            agent {
                docker {
                    image "${env.AWS_DOCKER_REGISTRY}/my-playwright:latest"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    netlify --version
                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
                    netlify status
                    netlify deploy --dir=build --json > deploy-output.json
                    CI_ENVIRONMENT_URL=$(jq -r '.deploy_url' deploy-output.json)
                    echo "✅ Staging deployed to: $CI_ENVIRONMENT_URL"
                    CI_ENVIRONMENT_URL="$CI_ENVIRONMENT_URL" npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Staging E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }

        stage('Deploy prod') {
            agent {
                docker {
                    image "${env.AWS_DOCKER_REGISTRY}/my-playwright:latest"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    node --version
                    netlify --version
                    echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"
                    netlify deploy --dir=build --prod --json > deploy-output.json
                    CI_ENVIRONMENT_URL=$(jq -r '.deploy_url' deploy-output.json)
                    echo "✅ Prod deployed to: $CI_ENVIRONMENT_URL"
                    CI_ENVIRONMENT_URL="$CI_ENVIRONMENT_URL" npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}