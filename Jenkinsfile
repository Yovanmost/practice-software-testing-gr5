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
        // DOCKER_HOST = 'tcp://host.docker.internal:2375'
    }

    options {
        timestamps()
    }

    stages {
        // stage('Docker Version') {
        //     steps {
        //         sh 'docker version'
        //     }
        // }

        stage('Verify Workspace & Git') {
            steps {
                echo "Agent workspace: ${WORKSPACE}"
                sh 'ls -la'
                sh 'git --version'
            }
        }

        // 🔧 Sequential install to avoid race condition
        stage('Install Backend Dependencies') {
            steps {
                dir("${env.API_DIR}") {
                    script {
                        // Check if PHPUnit is missing
                        // def needsInstall = !fileExists('vendor/bin/phpunit')
                        // if (needsInstall) {
                            echo "Installing Composer dependencies..."
                            sh '''
                                set -e
                                composer install --prefer-dist --no-interaction --optimize-autoloader
                                composer dump-autoload -o
                                php artisan config:clear || echo "config:clear failed"
                                php artisan cache:clear || echo "cache:clear failed"
                                php artisan view:clear || echo "view:clear failed"
                                php artisan route:clear || echo "route:clear failed"
                            '''
                        // } else {
                        //     echo "✔️ Skipping Composer install (PHPUnit already exists)"
                        // }
                    }
                }
            }
        }


        stage('Install Frontend Dependencies') {
            steps {
                dir("${env.UI_DIR}") {
                    script {
                        if (!fileExists('node_modules') || sh(script: "test package-lock.json -nt node_modules", returnStatus: true) == 0) {
                            echo "Installing npm dependencies..."
                            sh 'npm ci --legacy-peer-deps'
                        } else {
                            echo "✔️ Skipping npm install (no changes)"
                        }
                    }
                }
            }
        }

        // ✅ Tests in parallel
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

                // stage('Frontend Karma') {
                //     steps {
                //         dir("${env.UI_DIR}") {
                //             echo "Running Angular unit tests..."
                //             withEnv(["CHROME_BIN=${env.CHROME_BIN}"]) {
                //                 sh 'xvfb-run --auto-servernum -- npm run test -- --watch=false --browsers=ChromeHeadlessCI --code-coverage=false'
                //             }
                //         }
                //     }
                // }
            }
        }

        // // Optional stages for deploy/db/healthcheck can be added here
        stage('Deploy to Test') {
            steps {
                echo "🧪 Deploying test stack on port 8081..."
                sh '''
                    docker compose -f docker-compose.yml -f _docker/override-test.yml down || true
                    docker compose -f docker-compose.yml -f _docker/override-test.yml up -d --build
                '''
            }
        }
        // stage('Deploy to Test') {
        //     steps {
        //         sh '''
        //             echo "🧪 Deploying test stack on port 8081..."
        //             docker-compose -f docker-compose.yml -f _docker/override-test.yml down || true
        //             docker-compose -f docker-compose.yml -f _docker/override-test.yml up -d --build
        //         '''
        //     }
        // }

        // stage('Manual Approval for Production') {
        //     steps {
        //         input message: '✅ Review the test deployment and approve to deploy to production?'
        //     }
        // }

        // stage('Deploy to Production') {
        //     steps {
        //         sh '''
        //             echo "🚀 Deploying production stack on port 80..."
        //             docker-compose down || true
        //             docker-compose up -d --build
        //         '''
        //     }
        // }

        // stage('Optional: DB Migration & Seeding') {
        //     when {
        //         expression { return params.RUN_DB_SEED ?: false }
        //     }
        //     steps {
        //         sh 'docker-compose exec -T laravel-api php artisan migrate:fresh --seed || true'
        //     }
        // }
    }

    post {
        success {
            echo "✅ CI pipeline completed successfully!"
        }
        failure {
            echo "❌ CI pipeline failed!"
        }
        cleanup {
            echo "🧹 Cleanup: Removing unused build artifacts (but not full workspace)"
        }
    }

    parameters {
        booleanParam(name: 'RUN_DB_SEED', defaultValue: false, description: 'Run php artisan migrate:fresh --seed after deploy')
    }
}