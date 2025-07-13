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
        TEST_PROJECT = "ci-test"
        PROD_PROJECT = "ci-prod"
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
                echo "🚧 Deploying test environment on port 4200 (UI)..."
                sh """
                    ${COMPOSE} -p ${TEST_PROJECT} down || true
                    ${COMPOSE} -p ${TEST_PROJECT} up -d --build
                """
            }
        }

        stage('Manual Approval for Production') {
            steps {
                input message: '✅ Test deployment is up. Verify the app at http://localhost:4200. Click Continue to deploy to production.'
            }
        }

        stage('Teardown Test Environment') {
            steps {
                echo "🧹 Cleaning up test environment (wait 60s)..."
                sh """
                    ${COMPOSE} -p ${TEST_PROJECT} down || true
                    sleep 60
                """
            }
        }

        stage('Deploy Production Environment') {
            steps {
                echo "🚀 Deploying production stack (UI on different port)..."
                sh """
                    ${COMPOSE_PROD} -p ${PROD_PROJECT} down || true
                    ${COMPOSE_PROD} -p ${PROD_PROJECT} up -d --build
                """
            }
        }

        stage('Final Manual Approval') {
            steps {
                input message: '✅ Production deployed. Confirm everything is OK to finish the pipeline.'
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
            echo "🧹 Final cleanup step (test environment)..."
            sh "${COMPOSE} -p ${TEST_PROJECT} down || true"
            sh "${COMPOSE} -p ${PROD_PROJECT} down || true"
        }
    }
}
