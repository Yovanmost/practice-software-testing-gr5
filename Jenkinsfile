pipeline {
    agent {
        node {
            label 'my-jenkins-agent'
        }
    }

    environment {
        SPRINT_FOLDER = "sprint5-with-bugs"
        API_DIR = "${SPRINT_FOLDER}/API"
        COMPOSE = "docker compose -f docker-compose.yml"
        COMPOSE_PROD = "docker compose -f docker-compose.yml -f _docker/override-prod.yml"
        REQUIRED_PORTS = "4200 8091 8000 3306 1025 1080"
    }

    options {
        timestamps()
    }

    stages {
        stage('Checkout & Verify') {
            steps {
                echo "🔍 Verifying workspace and Git"
                sh 'git --version'
                sh 'ls -la'
            }
        }

        stage('Check Required Ports') {
            steps {
                echo "🔎 Checking if required ports are available..."
                script {
                    def ports = env.REQUIRED_PORTS.tokenize()
                    for (port in ports) {
                        def result = sh(script: "lsof -i :${port} || true", returnStdout: true).trim()
                        if (result) {
                            error "❌ Port ${port} is already in use!\n${result}"
                        } else {
                            echo "✅ Port ${port} is available"
                        }
                    }
                }
            }
        }

        stage('Install Backend Dependencies') {
            steps {
                dir("${env.API_DIR}") {
                    echo "📦 Installing Composer dependencies..."
                    sh '''
                        composer install --no-interaction --optimize-autoloader
                        php artisan config:clear || true
                        php artisan cache:clear || true
                        php artisan view:clear || true
                        php artisan route:clear || true
                    '''
                }

                dir("${env.UI_DIR}") {
                    echo "Installing Node.js dependencies for UI (e.g., Angular)..."
                    sh 'npm ci --legacy-peer-deps'
                }
            }
        }

        stage('Run Backend Unit Tests') {
            steps {
                dir("${env.API_DIR}") {
                    echo "🧪 Running PHPUnit tests..."
                    sh '''
                        if [ ! -f ./vendor/bin/phpunit ]; then
                            echo "❌ PHPUnit not found! Aborting..."
                            exit 1
                        fi
                        APP_ENV=testing ./vendor/bin/phpunit
                    '''
                }
            }
        }

        stage('Deploy Test Environment') {
            steps {
                echo "🚧 Deploying test environment..."
                sh """
                    ${COMPOSE} down || true
                    ${COMPOSE} up -d --build
                """
            }
        }

        stage('Manual Approval for Production') {
            steps {
                input message: '✅ Test environment is up at http://localhost:4200. Click Continue to deploy to production.'
            }
        }

        stage('Teardown Test Environment') {
            steps {
                echo "🧹 Stopping test containers (sleep 5s)..."
                sh """
                    ${COMPOSE} down || true
                    sleep 5
                """
            }
        }

        stage('Deploy Production Environment') {
            steps {
                echo "🚀 Deploying production environment (UI on port 4201)..."
                sh """
                    ${COMPOSE_PROD} down || true
                    ${COMPOSE_PROD} up -d --build
                """
            }
        }

        stage('Final Manual Approval') {
            steps {
                input message: '✅ Production deployed at http://localhost:4201. Confirm everything is OK to finish.'
            }
        }
    }

    post {
        success {
            echo "✅ CI pipeline completed successfully!"
        }
        failure {
            echo "❌ CI pipeline failed!"
        }
        always {
            echo "🧹 Final cleanup (if needed)..."
            sh "${COMPOSE} down || true"
            sh "${COMPOSE_PROD} down || true"
        }
    }
}
