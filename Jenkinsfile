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
      label 'my-jenkins-agent'
    }
  }

  // Initial minimal environment, you can still add safe constants here
  environment {
    COMPOSE_ROOT_DIR = "."
    DOCKER_COMPOSE_FILE = "docker-compose.yml"
  }

  options {
    skipDefaultCheckout true
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        script {
          checkout scm
        }
        echo "✅ Repo checked out"
      }
    }

    stage('Load .env file') {
      steps {
        script {
          echo "📥 Reading .env variables into Jenkins environment..."
          def envFile = readFile("${env.COMPOSE_ROOT_DIR}/.env").split('\n')
          for (line in envFile) {
            if (line.trim() && !line.startsWith('#')) {
              def (key, value) = line.tokenize('=')
              def k = key.trim()
              def v = value.trim()
              env[k] = v
              echo "→ Loaded env var: ${k}=${v}"
            }
          }
        }
      }
    }

    stage('Install Dependencies') {
      steps {
        echo "📦 Installing backend dependencies..."
        dir("${env.SPRINT_FOLDER}/API") {
          sh 'composer install --prefer-dist --optimize-autoloader'
          sh 'composer dump-autoload -o'
          sh 'php artisan config:clear'
          sh 'php artisan cache:clear'
          sh 'php artisan view:clear'
          sh 'php artisan route:clear'
        }

        echo "📦 Installing frontend dependencies..."
        dir("${env.SPRINT_FOLDER}/UI") {
          sh 'npm ci --legacy-peer-deps'
        }
      }
    }

    stage('Run Backend Unit Tests') {
      steps {
        echo "🧪 Running backend tests (Pest for sprint5-with-bugs, PHPUnit for others)..."
        dir("${env.SPRINT_FOLDER}/API") {
          script {
            if (env.SPRINT_FOLDER == "sprint5-with-bugs") {
              sh './vendor/bin/pest'
            } else {
              sh './vendor/bin/phpunit'
            }
          }
        }
      }
    }

    // Optional: You can add other stages (e.g., deployment, frontend tests) here.
  }

  post {
    failure {
      echo '❌ CI pipeline failed!'
    }
    success {
      echo '✅ CI pipeline completed successfully!'
    }
  }
}
