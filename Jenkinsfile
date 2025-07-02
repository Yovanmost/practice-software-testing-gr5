// Jenkins Pipeline script for backend (PHPUnit) and frontend (Angular) unit tests
// This pipeline runs tests directly on the Jenkins agent, without using Docker Compose for the tests themselves.

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
    }

    options {
        skipDefaultCheckout true
        timestamps()
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout scm
                }
                echo "Code checked out to: ${WORKSPACE}"
                echo "Listing contents of API directory: ${env.API_DIR}"
                sh "ls -la ${env.API_DIR}"
                echo "Listing contents of UI directory: ${env.UI_DIR}"
                sh "ls -la ${env.UI_DIR}"
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "Installing PHP dependencies using Composer on the agent..."
                dir("${env.API_DIR}") {
                    sh 'composer install --prefer-dist --optimize-autoloader'
                    sh 'composer dump-autoload -o'
                    sh 'php artisan config:clear'
                    sh 'php artisan cache:clear'
                    sh 'php artisan view:clear'
                    sh 'php artisan route:clear'
                }

                echo "Installing Node.js dependencies for UI (Angular)..."
                dir("${env.UI_DIR}") {
                    sh 'npm ci --legacy-peer-deps'
                }
            }
        }

        stage('Run Backend Unit Tests') {
            steps {
                echo "Running PHP unit/feature tests directly on the agent."
                dir("${env.API_DIR}") {
                    sh 'APP_ENV=testing ./vendor/bin/phpunit'
                }
            }
        }

        stage('Run Frontend Unit Tests (Karma/Jasmine)') {
            steps {
                echo "Executing Angular unit tests using Karma and ChromeHeadless..."
                dir("${env.UI_DIR}") {
                    withEnv(["CHROME_BIN=/usr/bin/chromium"]) {
                        sh 'xvfb-run --auto-servernum -- npm run test -- --watch=false --browsers=ChromeHeadlessCI'
                    }
                }
            }
        }

        stage('Deploy App (Docker Compose)') {
            steps {
                echo "Deploying application using Docker Compose on Docker host..."
                // ✅ FIX: Inject SPRINT_FOLDER
                withEnv([
                    "DOCKER_HOST=tcp://docker-tcp-relay:2375",
                    "SPRINT_FOLDER=${env.SPRINT_FOLDER}"
                ]) {
                    sh 'docker-compose down || true'
                    sh 'docker-compose up -d --build'
                }
            }
        }

        stage('Debug Artisan Path') {
            steps {
                // ✅ FIX: Inject SPRINT_FOLDER
                withEnv([
                    "DOCKER_HOST=tcp://docker-tcp-relay:2375",
                    "SPRINT_FOLDER=${env.SPRINT_FOLDER}"
                ]) {
                    sh 'docker-compose exec -T laravel-api ls -la /var/www'
                }
            }
        }

        stage('Debug .env Contents') {
            steps {
                echo "Checking contents of .env file..."
                sh 'cat .env || echo ".env file not found!"'
            }
        }

        stage('Debug docker-compose config') {
            steps {
                echo "Resolving docker-compose configuration..."
                sh 'docker-compose config'
            }
        }

        stage('Debug Jenkins Workspace') {
            steps {
                echo "Jenkins is in workspace: ${WORKSPACE}"
                sh 'ls -la'
            }
        }

        stage('Debug Docker Context') {
            steps {
                sh 'docker version'
                sh 'docker context ls'
            }
        }



        stage('Seed Test Database') {
            steps {
                echo "Running migrations and seeding database..."
                // ✅ FIX: Inject SPRINT_FOLDER
                withEnv([
                    "DOCKER_HOST=tcp://docker-tcp-relay:2375",
                    "SPRINT_FOLDER=${env.SPRINT_FOLDER}"
                ]) {
                    sh 'docker-compose exec -T laravel-api php artisan migrate:fresh --seed'
                }
            }
        }

        stage('Health Check') {
            steps {
                echo "Checking if API is reachable..."
                sh 'curl --fail http://localhost:8091/api/health || echo "API not responding (yet)"'
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Cleaning up workspace..."
            deleteDir()
        }
        failure {
            echo '❌ CI pipeline completed with failures!'
        }
        success {
            echo '✅ CI pipeline completed successfully!'
        }
    }
}
