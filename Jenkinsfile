pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '446782d0-a28a-461b-8276-49bf24d90fa9'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }

    stages {
            stage('Deploy staging')
             {
                agent 
                {
                    docker {
                    image 'node:18-alpine'
                    reuseNode true
                            }   
                }

                steps 
                {
                    sh '''
                    npm install netlify-cli@20.1.1 node-jq
                    node_modules/.bin/netlify --version
                    echo "Deploying to stage. Site ID: $NETLIFY_SITE_ID"
                    node_modules/.bin/netlify deploy --dir=build --json > deploy-output.json
                '''

                script
                {
                    env.STAGING_URL = sh(script: "node_modules/.bin/node-jq -r '.deploy_url' deploy_output.json", returnStdout: true)
                }
                }
                }

            stage('Staging E2E') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
                        environment 
                        {
                            CI_ENVIRONMENT_URL = "${env.STAGING_URL}"
                        }

                    steps {
                        sh '''
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                icon: '',
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Staging HTML Report',
                                reportTitles: '',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }


            stage('approval')
            {
                steps 
                {
                    timeout(time: 1, unit: 'MINUTES') 
                    {
                      input message: 'Do you wish to deploy to production?', ok: 'Yes, I am sure!'
                    }
              
                 }
            }

            stage('Deploy prod') 
            {
                agent 
                {
                    docker 
                    {
                        image 'node:18-alpine'
                        reuseNode true
                    }
                }

                 steps 
                 {
                        sh '''
                        npm install netlify-cli@20.1.1
                        node_modules/.bin/netlify --version
                        echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"
                        node_modules/.bin/netlify status
                        node_modules/.bin/netlify deploy --dir=build --prod
                        '''
                }
           }

          stage('Prod E2E') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
                        environment 
                        {
                            CI_ENVIRONMENT_URL = 'https://boisterous-tapioca-85ca92.netlify.app'
                        }
                    
                    steps {
                        sh '''
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                icon: '',
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Prod HTML Report',
                                reportTitles: '',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
    }
}
