// pipeline {
//   agent {
//     node {
//       label 'my-jenkins-agent'
//     }
//   }

//   environment {
//     // Keep only environment variables relevant to direct commands on the agent
//     // DOCKER_HOST and COMPOSE_FILE are no longer needed if not using docker-compose locally for tests
//     API_DIR = "sprint5-with-bugs/API"
//     UI_DIR = "sprint5-with-bugs/UI"
//   }

//   options {
//     skipDefaultCheckout true
//     timestamps()
//   }

//   stages {
//     stage('Checkout') {
//       steps {
//         script {
//           checkout scm
//         }
//       }
//     }

//     // --- The following stages are removed as they pertain to local Docker Compose orchestration for testing ---
//     // stage('Clean Up Previous Run (Pre-Build)')
//     // stage('Build Services')
//     // stage('Setup Test Environment')

//     stage('Install Dependencies') {
//       steps {
//         echo "Installing PHP dependencies using Composer on the agent..."
//         dir("${env.API_DIR}") { // Change directory to your Laravel API folder
//           // sh 'composer install --no-dev --prefer-dist --optimize-autoloader'
//           sh 'composer install --prefer-dist --optimize-autoloader'
//           sh 'composer dump-autoload -o'
//           sh 'php artisan config:clear' // Still useful for clearing Laravel cache on the agent
//         }

//         echo "Installing Node.js dependencies using npm on the agent..."
//         dir("${env.UI_DIR}") { // Change directory to your Angular UI folder
//           sh 'npm ci --legacy-peer-deps' // Continue using this for dependency resolution
//         }
//       }
//     }

//     stage('Run Backend Tests') {
//       steps {
//         echo "Running PHP unit/feature tests directly on the agent..."
//         dir("${env.API_DIR}") {
//           // IMPORTANT: Your phpunit.xml (or pest.xml) MUST be configured to use
//           // an in-memory SQLite database (e.g., <env name="DB_CONNECTION" value="sqlite"/>
//           // <env name="DB_DATABASE" value=":memory:"/>) or mock database connections.
//           // There will be no running MariaDB container for these tests.
//           // sh './vendor/bin/pest' // Or './vendor/bin/phpunit'
//           sh './vendor/bin/phpunit'
//         }
//       }
//     }

//     stage('Run Frontend Tests') {
//       steps {
//         echo "Running Playwright tests directly on the agent."
//         echo "Note: These tests should either be component-level, or configured to hit an external URL (e.g., a staging environment)."
//         dir("${env.UI_DIR}") {
//           // Playwright will run, but it will NOT find your local Dockerized API/Web on localhost:8091.
//           // You must ensure playwright.config.ts points to a valid external URL if it's
//           // performing end-to-end tests, or these should be pure component tests.
//           sh 'npx playwright test'
//         }
//       }
//     }

//     // --- If Jenkins is meant to *deploy* your application (like deploy.yml),
//     //     you would add a 'Deploy' stage here. This would involve commands
//     //     to push code to a remote server, SSH into it, and potentially
//     //     run docker-compose commands *on that remote server*.
//     // stage('Deploy Application') {
//     //   steps {
//     //     echo "Triggering remote deployment..."
//     //     // Example: sh 'ssh user@your-remote-server "cd /path/to/app && docker-compose pull && docker-compose up -d -force-recreate"'
//     //     // Or use a deployment tool like Capistrano, Deployer, or Ansible.
//     //   }
//     // }
//   }

//   post {
//     always {
//       // No local Docker services were brought up, so no need to bring them down.
//       echo "No local Docker services to bring down."
//     }

//     failure {
//       echo '❌ Build or tests failed!'
//     }

//     success {
//       echo '✅ CI pipeline completed successfully!'
//     }
//   }
// }

pipeline {
  agent {
    node {
      label 'my-jenkins-agent' // Ensure this agent has Docker and Docker Compose installed
    }
  }

  environment {
    // These paths are relative to the Jenkins workspace root
    API_DIR = "sprint5-with-bugs/API"
    UI_DIR = "sprint5-with-bugs/UI"
    // COMPOSE_ROOT_DIR is '.' because docker-compose.yml is at the workspace root
    COMPOSE_ROOT_DIR = "."
    DOCKER_COMPOSE_FILE = "docker-compose.yml" // Name of your Docker Compose file
    // NEW: Absolute path for the API source code for Docker Compose volume mount
    API_SOURCE_PATH = "${WORKSPACE}/${API_DIR}" // <--- ADD THIS LINE
    SPRINT_FOLDER = "sprint5-with-bugs"
  }

  options {
    skipDefaultCheckout true // Assume Jenkins handles SCM checkout externally
    timestamps() // Add timestamps to log output for readability
  }

  stages {
    stage('Checkout') {
      steps {
        script {
          checkout scm // Ensures the workspace is populated with your code
        }
        // Add this line directly after checkout
        echo "Listing contents of API_DIR on Jenkins agent host..."
        sh "ls -la ${env.API_DIR}"
        echo "Listing contents of COMPOSE_ROOT_DIR on Jenkins agent host..."
        sh "ls -la ${env.COMPOSE_ROOT_DIR}"
        sh "ls -la ${env.COMPOSE_ROOT_DIR}/${env.DOCKER_COMPOSE_FILE}" // Verify compose file presence
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

        echo "Installing Node.js dependencies for UI (e.g., Angular)..."
        dir("${env.UI_DIR}") {
          sh 'npm ci --legacy-peer-deps'
        }
      }
    }

    stage('Run Backend Unit Tests') {
      steps {
        echo "Running PHP unit/feature tests directly on the agent (using in-memory SQLite)..."
        dir("${env.API_DIR}") {
          sh 'APP_ENV=testing ./vendor/bin/phpunit'
        }
      }
    }

    // stage('Setup E2E Environment (Docker Compose)') {
    //   steps {
    //     echo "Ensuring a clean Docker Compose environment before starting..."
    //     dir("${env.COMPOSE_ROOT_DIR}") {
    //       // This command will tear down any existing services for this project.
    //       // '|| true' ensures the step doesn't fail if no containers are running (e.g., first build).
    //       sh 'docker-compose -f "${DOCKER_COMPOSE_FILE}" down -v --remove-orphans || true'
    //     }

    //     echo "Displaying the docker-compose.yml content being used by this Jenkins build:"
    //     dir("${env.COMPOSE_ROOT_DIR}") {
    //       sh 'cat "${DOCKER_COMPOSE_FILE}"'
    //     }

    //     echo "Verifying contents of host API directory: ${API_SOURCE_PATH}"
    //     sh "ls -la ${API_SOURCE_PATH}"
    //     sh "test -f ${API_SOURCE_PATH}/artisan && echo 'artisan found on host!' || echo 'artisan NOT found on host!'"

    //     echo "Starting Docker containers for E2E tests using docker-compose..."
    //     dir("${env.COMPOSE_ROOT_DIR}") {
    //       sh 'export DISABLE_LOGGING=true'
    //       // sh 'docker-compose -f "${DOCKER_COMPOSE_FILE}" up -d'
    //       sh "API_SOURCE_PATH=${env.API_SOURCE_PATH} docker-compose -f \"${env.DOCKER_COMPOSE_FILE}\" up -d"
    //     }

    //     echo "Waiting for services to become ready (60 seconds)..."
    //     sh 'sleep 60s'

    //     echo "🔧 Fixing /var/www ownership inside laravel-api container..."
    //     sh 'docker-compose exec -T laravel-api chown -R 1000:1000 /var/www'


    //     dir("${WORKSPACE}") {
    //         echo "Listing contents of /var/www in laravel-api container..."
    //         sh 'docker-compose exec -T laravel-api ls -la /var/www'
    //         echo "Checking owner/permissions of /var/www in laravel-api container..."
    //         sh 'docker-compose exec -T laravel-api stat /var/www'
    //         echo "Attempting to create a test file in /var/www inside laravel-api container..."
    //         sh 'docker-compose exec -T laravel-api touch /var/www/test_file.txt'
    //         sh 'docker-compose exec -T laravel-api ls -la /var/www'
    //     }

    //     echo "Listing contents of /var/www in laravel-api container..."
    //     dir("${env.COMPOSE_ROOT_DIR}") {
    //         // Add this line to debug
    //         sh 'docker-compose exec -T laravel-api ls -la /var/www'
    //     }

    //     echo "Creating and seeding database for E2E tests..."
    //     dir("${env.COMPOSE_ROOT_DIR}") {
    //       sh 'docker-compose exec -T laravel-api php artisan migrate:refresh --seed'
    //     }

    //     echo "Performing health checks on API (optional, but good for diagnostics)..."
    //     sh 'curl -v -X GET "http://localhost:8091/status"'
    //     sh '''curl -v -X POST "http://localhost:8091/users/login" \
    //       -H "Content-Type: application/json" \
    //       --data-raw \'{"email":"customer@practicesoftwaretesting.com","password":"welcome01"}\''''
    //   }
    // }

    // stage('Run Frontend E2E Tests (Playwright)') {
    //   steps {
    //     echo "Running Playwright E2E tests against the running Dockerized services."
    //     dir("${env.COMPOSE_ROOT_DIR}") { // This is where playwright.config.ts now lives
    //       sh 'npx playwright test'
    //     }
    //   }
    // }

    stage('Run Frontend Unit Tests') {
      agent {
        docker {
          image 'node:18' // Node.js v18 is compatible with Angular 15
        }
      }
      environment {
        UI_DIR = 'sprint5/UI'
      }
      steps {
        dir("${UI_DIR}") {
          echo '📦 Installing Node.js dependencies...'
          sh 'npm ci --legacy-peer-deps'

          echo '🧱 Installing Chrome dependencies...'
          sh '''
            apt-get update
            apt-get install -y libnss3 libxss1 libasound2 \
              fonts-liberation libappindicator3-1 libatk-bridge2.0-0 \
              libgtk-3-0 libxshmfence1 xvfb
          '''

          echo '🧪 Running Angular unit tests (Karma + ChromeHeadless)...'
          sh 'xvfb-run --auto-servernum -- npm run test -- --watch=false --browsers=ChromeHeadless'
        }
      }
    }

  }

  post {
    always {
      echo "Tearing down Docker containers..."
      dir("${env.COMPOSE_ROOT_DIR}") {
        sh 'docker-compose -f "${DOCKER_COMPOSE_FILE}" down -v --remove-orphans'
      }
    }

    failure {
      echo '❌ CI pipeline completed with failures!'
    }

    success {
      echo '✅ CI pipeline completed successfully!'
    }
  }
}