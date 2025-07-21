pipeline {
    agent any

    stages
     {
        stage('Build') 
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
                    ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                '''
            }
        }
        stage('Test') 
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
                    echo "test-stage"
                    test -f build/index.html
                    npm test
                '''
            }
        }

         stage('E2E') 
        {
            agent
            {
                docker 
                {
                    image 'mcr.microsoft.com/playwright:v1.54.0-noble'
                    reuseNode true
                }
            }
            steps
            {
                sh '''
                    npm install serve
                    node_modules/.bin/serve -s build &
                    sleep 10
                    npx playwwright test
                '''
            }
        }
    }

    post {
        always {
            junit 'test-results/junit.xml'
        }
    }
}
