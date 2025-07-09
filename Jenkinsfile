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

        COMPOSE = "docker compose -f docker-compose.yml"
        TEST_PROJECT = "ci-test"
        PROD_PROJECT = "ci-prod"
    }

    options {
        timestamps()
    }

    parameters {
        booleanParam(name: 'RUN_DB_SEED', defaultValue: false, description: 'Run php artisan migrate:fresh --seed after deploy')
    }

    stages {
        stage('Verify Workspace & Git') {
            steps {
                echo "Agent workspace: ${env.WORKSPACE}"
                sh 'ls -la'
                sh 'git --version'
            }
        }

        stage('Ensure Clean Test Deployment') {
            steps {
                echo "⛔ Stopping previous test deployment (if running)..."
                sh "${COMPOSE} -p ${TEST_PROJECT} down || true"
            }
        }

        stage('Clean Workspace') {
            steps {
                echo "🧹 Cleaning node_modules before npm install..."
                dir("${env.UI_DIR}") {
                    sh '''
                        sudo rm -rf node_modules package-lock.json || true
                        sudo chown -R $USER:$USER . || true
                    '''
                }
            }
        }

        stage('Install Backend Dependencies') {
            steps {
                dir("${env.API_DIR}") {
                    echo "Installing Composer dependencies..."
                    sh '''
                        set -e
                        composer install --prefer-dist --no-interaction --optimize-autoloader
                        composer dump-autoload -o
                        php artisan config:clear || true
                        php artisan cache:clear || true
                        php artisan view:clear || true
                        php artisan route:clear || true
                    '''
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('Backend PHPUnit') {
                    steps {
                        dir("${env.API_DIR}") {
                            echo "Running Laravel tests..."
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

                // Add frontend tests here if needed
            }
        }

        stage('Deploy to Test') {
            steps {
                echo "🧪 Deploying test stack on port 8081..."
                sh """
                    ${COMPOSE} -p ${TEST_PROJECT} down || true
                    ${COMPOSE} -p ${TEST_PROJECT} up -d --build
                """
            }
        }

        stage('Optional: DB Migration & Seeding (Test)') {
            when {
                expression { return params.RUN_DB_SEED ?: false }
            }
            steps {
                echo "🌱 Running DB migrate:fresh --seed after test deployment..."
                sh """
                    ${COMPOSE} -p ${TEST_PROJECT} exec -T laravel-api php artisan migrate:fresh --seed
                """
            }
        }

        stage('Manual Approval for Production') {
            steps {
                input message: '✅ Test deployment complete. Manually verify the app at http://localhost:4200 and click Continue to deploy to production.'
            }
        }

        stage('Deploy to Production') {
            steps {
                echo "🚀 Deploying production stack on port 80..."
                sh """
                    docker compose -f docker-compose.yml -f _docker/override-prod.yml -p ${PROD_PROJECT} down || true
                    docker compose -f docker-compose.yml -f _docker/override-prod.yml -p ${PROD_PROJECT} up -d --build
                """
            }
        }

        stage('Optional: DB Migration & Seeding (Production)') {
            when {
                expression { return params.RUN_DB_SEED ?: false }
            }
            steps {
                echo "🌱 Running DB migrate:fresh --seed for production..."
                sh """
                    docker compose -f docker-compose.yml -f _docker/override-prod.yml -p ${PROD_PROJECT} exec -T laravel-api php artisan migrate:fresh --seed
                """
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
            echo "🧹 Cleanup: Stopping test containers..."
            sh "${COMPOSE} -p ${TEST_PROJECT} down || true"
        }
    }
}
