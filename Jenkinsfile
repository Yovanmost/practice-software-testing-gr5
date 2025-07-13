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
        CONTAINER_USER = "www-data"
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

        stage('Deploy Test Environment') {
            steps {
                echo "🚧 Starting services..."
                sh """
                    ${COMPOSE} down || true
                    ${COMPOSE} up -d --build
                """
            }
        }

        // stage('Install Backend Dependencies') {
        //     steps {
        //         echo "📦 Installing Composer dependencies inside container as non-root..."
        //         sh """
        //             ${COMPOSE} exec -T --user=${CONTAINER_USER} laravel-api sh -c '
        //                 composer install --no-interaction --optimize-autoloader &&
        //                 php artisan config:clear || true &&
        //                 php artisan cache:clear || true &&
        //                 php artisan view:clear || true &&
        //                 php artisan route:clear || true
        //             '
        //         """
        //     }
        // }

        // stage('Run Backend Unit Tests') {
        //     steps {
        //         echo "🧪 Running PHPUnit tests..."
        //         sh """
        //             ${COMPOSE} exec -T --user=${CONTAINER_USER} laravel-api sh -c '
        //                 if [ ! -f ./vendor/bin/phpunit ]; then
        //                     echo "❌ PHPUnit not found! Aborting..."
        //                     exit 1
        //                 fi
        //                 APP_ENV=testing ./vendor/bin/phpunit
        //             '
        //         """
        //     }
        // }

        stage('Manual Approval to Finish') {
            steps {
                input message: '✅ Test environment is up. Visit the app at http://localhost:4200. Click Continue when done testing.'
            }
        }

        stage('Teardown Test Environment') {
            steps {
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
