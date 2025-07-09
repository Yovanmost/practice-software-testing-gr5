// // Jenkins Pipeline script for backend (PHPUnit) and frontend (Angular) unit tests
// // This pipeline runs tests directly on the Jenkins agent, without using Docker Compose for the tests themselves.

// pipeline {
//     agent {
//         node {
//             label 'my-jenkins-agent'
//         }
//     }

//     environment {
//         SPRINT_FOLDER = "sprint5-with-bugs"
//         API_DIR = "sprint5-with-bugs/API"
//         UI_DIR = "sprint5-with-bugs/UI"
//     }

//     options {
//         skipDefaultCheckout true
//         timestamps()
//     }

//     stages {
//         stage('Checkout Code') {
//             steps {
//                 script {
//                     checkout scm
//                 }
//                 echo "Code checked out to: ${WORKSPACE}"
//                 echo "Listing contents of API directory: ${env.API_DIR}"
//                 sh "ls -la ${env.API_DIR}"
//                 echo "Listing contents of UI directory: ${env.UI_DIR}"
//                 sh "ls -la ${env.UI_DIR}"
//             }
//         }

//         stage('Install Dependencies') {
//             steps {
//                 echo "Installing PHP dependencies using Composer on the agent..."
//                 dir("${env.API_DIR}") {
//                     sh 'composer install --prefer-dist --optimize-autoloader'
//                     sh 'composer dump-autoload -o'
//                     sh 'php artisan config:clear'
//                     sh 'php artisan cache:clear'
//                     sh 'php artisan view:clear'
//                     sh 'php artisan route:clear'
//                 }

//                 echo "Installing Node.js dependencies for UI (Angular)..."
//                 dir("${env.UI_DIR}") {
//                     sh 'npm ci --legacy-peer-deps'
//                 }
//             }
//         }

//         stage('Run Backend Unit Tests') {
//             steps {
//                 echo "Running PHP unit/feature tests directly on the agent."
//                 dir("${env.API_DIR}") {
//                     sh 'APP_ENV=testing ./vendor/bin/phpunit'
//                 }
//             }
//         }

//         stage('Run Frontend Unit Tests (Karma/Jasmine)') {
//             steps {
//                 echo "Executing Angular unit tests using Karma and ChromeHeadless..."
//                 dir("${env.UI_DIR}") {
//                     withEnv(["CHROME_BIN=/usr/bin/chromium"]) {
//                         sh 'xvfb-run --auto-servernum -- npm run test -- --watch=false --browsers=ChromeHeadlessCI'
//                     }
//                 }
//             }
//         }

//         stage('Deploy App (Docker Compose)') {
//             steps {
//                 echo "Deploying application using Docker Compose on Docker host..."
//                 // ✅ FIX: Inject SPRINT_FOLDER
//                 withEnv([
//                     "DOCKER_HOST=tcp://docker-tcp-relay:2375",
//                     "SPRINT_FOLDER=${env.SPRINT_FOLDER}"
//                 ]) {
//                     sh 'docker-compose down || true'
//                     sh 'docker-compose up -d --build'
//                 }
//             }
//         }

//         stage('Seed Test Database') {
//             steps {
//                 echo "Running migrations and seeding database..."
//                 // ✅ FIX: Inject SPRINT_FOLDER
//                 withEnv([
//                     "DOCKER_HOST=tcp://docker-tcp-relay:2375",
//                     "SPRINT_FOLDER=${env.SPRINT_FOLDER}"
//                 ]) {
//                     sh 'docker-compose run -T laravel-api php artisan migrate:fresh --seed'
//                 }
//             }
//         }

//         stage('Health Check') {
//             steps {
//                 echo "Checking if API is reachable..."
//                 sh 'curl --fail http://localhost:8091/api/health || echo "API not responding (yet)"'
//             }
//         }
//     }

//     post {
//         always {
//             echo "Pipeline finished. Cleaning up workspace..."
//             deleteDir()
//         }
//         failure {
//             echo '❌ CI pipeline completed with failures!'
//         }
//         success {
//             echo '✅ CI pipeline completed successfully!'
//         }
//     }
// }

pipeline {
    agent {
        node {
            label 'my-jenkins-agent'
        }
    }

    environment {
        SPRINT_FOLDER = "sprint5-with-bugs"
        API_DIR = "sprint5-with-bugs/API"
        UI_DIR = "sprint5-with-bugs/UI"
        CHROME_BIN = "/usr/bin/chromium"
    }

    options {
        timestamps()
    }

    parameters {
        booleanParam(name: 'RUN_DB_SEED', defaultValue: false, description: 'Run php artisan migrate:fresh --seed')
    }

    stages {
        stage('Verify Workspace & Git') {
            steps {
                echo "Workspace: ${WORKSPACE}"
                sh 'ls -la'
                sh 'git --version'
            }
        }

        stage('Stop Previous Test Deployment') {
            steps {
                sh 'docker compose -f docker-compose.yml -f _docker/override-test.yml down || true'
            }
        }

        stage('Run Backend Unit Tests') {
            steps {
                dir("${env.API_DIR}") {
                    sh '''
                        rm -rf vendor
                        mkdir -p vendor
                        chown -R $(id -u):$(id -g) .
                        composer install --prefer-dist --no-interaction
                        php artisan config:clear || true
                        php artisan route:clear || true
                    '''
                }
            }
        }

        stage('Deploy to Test') {
            steps {
                echo "Deploying to test (port 8091)..."
                sh '''
                    docker compose -f docker-compose.yml -f _docker/override-test.yml up -d --build
                '''
            }
        }

        stage('Optional: DB Migration & Seeding') {
            when {
                expression { return params.RUN_DB_SEED }
            }
            steps {
                sh '''
                    docker compose -f docker-compose.yml exec -T laravel-api php artisan migrate:fresh --seed
                '''
            }
        }

        stage('Manual Approval Before Production') {
            steps {
                input message: '✅ App deployed to test at http://localhost:8091. Manually verify and click Continue to deploy to production.'
            }
        }

        stage('Deploy to Production') {
            steps {
                echo "🚀 Deploying to production (port 80)..."
                sh '''
                    docker compose -f docker-compose.yml -f docker-compose.override-prod.yml down || true
                    docker compose -f docker-compose.yml -f docker-compose.override-prod.yml up -d --build
                '''
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD pipeline completed!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        always {
            echo "🧹 Stopping test and prod containers to avoid leftover..."
            sh '''
                docker compose -f docker-compose.yml -f _docker/override-test.yml down || true
                docker compose -f docker-compose.yml -f docker-compose.override-prod.yml down || true
            '''
        }
    }
}
