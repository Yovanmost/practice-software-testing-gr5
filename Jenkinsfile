// Jenkins Pipeline script for backend (PHPUnit) and frontend (Angular) unit tests
// This pipeline runs tests directly on the Jenkins agent, without using Docker Compose for the tests themselves.

pipeline {
    // Define the Jenkins agent where this pipeline will run.
    // Ensure 'my-jenkins-agent' is a Docker agent built from your provided Dockerfile.
    agent {
        node {
            label 'my-jenkins-agent'
        }
    }

    environment {
        // Define paths relative to the Jenkins workspace root
        API_DIR = "sprint5-with-bugs/API"
        UI_DIR = "sprint5-with-bugs/UI"
    }

    options {
        skipDefaultCheckout true // Assume Jenkins handles SCM checkout externally
        timestamps() // Add timestamps to log output for readability
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout scm // Ensures the workspace is populated with your code
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
                    // Using --no-dev is usually good for CI, unless you need dev dependencies for tests
                    sh 'composer install --prefer-dist --optimize-autoloader'
                    sh 'composer dump-autoload -o'
                    // Clear Laravel caches; good practice on a fresh environment
                    sh 'php artisan config:clear'
                    sh 'php artisan cache:clear'
                    sh 'php artisan view:clear'
                    sh 'php artisan route:clear'
                }

                echo "Installing Node.js dependencies for UI (Angular)..."
                dir("${env.UI_DIR}") {
                    // 'npm ci' is preferred for CI as it's faster and uses package-lock.json
                    sh 'npm ci --legacy-peer-deps'
                }
            }
        }

        stage('Run Backend Unit Tests') {
            steps {
                echo "Running PHP unit/feature tests directly on the agent."
                echo "Assuming phpunit.xml is configured to use in-memory SQLite (DB_CONNECTION=sqlite, DB_DATABASE=:memory:)."
                dir("${env.API_DIR}") {
                    // Set APP_ENV to testing to ensure Laravel loads test-specific configurations
                    sh 'APP_ENV=testing ./vendor/bin/phpunit'
                    // If you use PestPHP:
                    // sh 'APP_ENV=testing ./vendor/bin/pest'
                }
            }
        }


        stage('Run Frontend Unit Tests (Karma/Jasmine)') {
            steps {
                echo "Executing Angular unit tests using Karma and ChromeHeadless..."
                dir("${sprint5/UI}") {
                    // 'xvfb-run' provides a virtual display for ChromeHeadless, crucial on headless servers.
                    // '--watch=false' ensures tests run once and exit.
                    // '--browsers=ChromeHeadless' explicitly tells Karma to use headless Chrome.
                    sh 'xvfb-run --auto-servernum -- npm run test -- --watch=false --browsers=ChromeHeadless'
                }
            }
        }

        // Optional: If you have Playwright E2E tests that can hit an *external* URL (e.g., a deployed staging environment)
        // and do not need a locally running docker-compose setup, you could uncomment and adjust this.
        // stage('Run Frontend E2E Tests (Playwright - External URL)') {
        //   steps {
        //     echo "Running Playwright E2E tests against an external environment."
        //     echo "Ensure playwright.config.ts is configured with an appropriate baseURL."
        //     dir("${env.UI_DIR}") {
        //       sh 'npx playwright test'
        //     }
        //   }
        // }
    }

    post {
        always {
            echo "Pipeline finished. Cleaning up workspace..."
            // Clean the workspace to ensure a fresh start for the next build.
            deleteDir()
        }
        failure {
            echo '❌ CI pipeline completed with failures!'
            // Optionally archive test reports if your test runners generate them (e.g., JUnit XML, HTML coverage)
            // archiveArtifacts artifacts: "${env.API_DIR}/junit-report.xml", allowEmpty: true
            // archiveArtifacts artifacts: "${env.UI_DIR}/coverage/**", allowEmpty: true
        }
        success {
            echo '✅ CI pipeline completed successfully!'
        }
    }
}