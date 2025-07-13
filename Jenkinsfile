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
        REQUIRED_PORTS = "4200 8091 8000 3306 1025 1080"
    }

    options {
        timestamps()
    }

    stages {

        stage('Get Host UID/GID') {
            steps {
                script {
                    env.HOST_UID = sh(script: "id -u", returnStdout: true).trim()
                    env.HOST_GID = sh(script: "id -g", returnStdout: true).trim()
                }
            }
        }

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

        stage('Build for Test (Composer dev + test)') {
            steps {
                echo "🔧 Building backend for testing (including dev dependencies)..."
                sh """
                    ${COMPOSE} down || true
                    HOST_UID=${env.HOST_UID} HOST_GID=${env.HOST_GID} ${COMPOSE} up -d --build
                    ${COMPOSE} exec -T laravel-api sh -c '
                        composer update --no-progress --prefer-dist &&
                        php artisan config:clear || true &&
                        php artisan cache:clear || true &&
                        php artisan view:clear || true &&
                        php artisan route:clear || true
                    '
                """
            }
        }

        stage('Fix Vendor Permissions') {
            steps {
                echo "🔧 Fixing vendor folder ownership for Jenkins agent..."
                sh """
                    ${COMPOSE} exec --user root -T laravel-api sh -c '
                        chown -R ${HOST_UID}:${HOST_GID} /var/www/vendor || true
                    '
                """
            }
        }

        stage('Run Backend Unit Tests') {
            steps {
                echo "🧪 Running PHPUnit tests..."
                sh """
                    ${COMPOSE} exec -T laravel-api sh -c '
                        if [ -f ./vendor/bin/pest ]; then
                            APP_ENV=testing ./vendor/bin/pest
                        elif [ -f ./vendor/bin/phpunit ]; then
                            APP_ENV=testing ./vendor/bin/phpunit
                        else
                            echo "❌ No test runner found. Aborting..."
                            exit 1
                        fi
                    '
                """
            }
        }

        stage('Install Production Dependencies') {
            steps {
                echo "📦 Switching to production dependencies..."
                sh """
                    ${COMPOSE} exec -T laravel-api sh -c '
                        composer install --no-dev --optimize-autoloader &&
                        composer dump-autoload -o
                    '
                """
            }
        }

        stage('Deploy Test Environment') {
            steps {
                input message: '✅ Tests passed. Continue to deploy test environment?'
                echo "🚀 Deploying test environment with production dependencies..."
                sh """
                    HOST_UID=${env.HOST_UID} HOST_GID=${env.HOST_GID} ${COMPOSE} restart || true
                """
            }
        }

        stage('Teardown Test Environment') {
            steps {
                input message: '🧹 Finished testing manually? Proceed to teardown?'
                echo "🧹 Stopping and cleaning up containers..."
                sh """
                    ${COMPOSE} down || true
                    sleep 5
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
            echo "🧹 Final cleanup (if needed)..."
            sh "${COMPOSE} down || true"
        }
    }
}
