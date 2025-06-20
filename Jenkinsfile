pipeline {
  agent {
    node {
      label 'my-jenkins-agent'
    }
  }

  environment {
    COMPOSE_FILE = 'docker-compose.yml'
    DOCKER_HOST = "tcp://docker-tcp-relay:2375"
    // Define the path to your API and UI directories relative to the workspace root
    API_DIR = "sprint5-with-bugs/API"
    UI_DIR = "sprint5-with-bugs/UI"
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
      }
    }

    stage('Build Services') {
      steps {
        sh 'pwd' // Confirm current working directory
        sh 'ls -l' // List contents of the workspace root
        sh 'cat docker-compose.yml' // Keep this for verification if needed
        // Build your application images first
        sh 'docker-compose build --no-cache'
      }
    }

    stage('Install Dependencies') {
      steps {
        echo "Installing PHP dependencies using Composer on the agent..."
        dir("${env.API_DIR}") { // Change directory to your Laravel API folder
          sh 'composer install --no-dev --prefer-dist --optimize-autoloader' // Or 'composer update' as per deploy.yml
          sh 'composer dump-autoload -o' // As seen in deploy.yml
          sh 'php artisan config:clear' // Now this runs on the agent too, directly
        }

        echo "Installing Node.js dependencies using npm on the agent..."
        dir("${env.UI_DIR}") { // Change directory to your Angular UI folder
          sh 'npm ci' // Use npm ci for clean, reproducible installs like GitHub Actions
          // If npm ci fails due to peer deps, you might need 'npm install --force' or 'npm install --legacy-peer-deps'
        }
      }
    }

    stage('Setup Test Environment') {
        steps {
            echo "Starting Docker services for testing..."
            sh 'docker-compose up -d'
            sh 'sleep 60s' // Give services time to start, especially DB
            echo "Creating and seeding database..."
            sh 'docker-compose exec -T laravel-api php artisan migrate:refresh --seed'
            echo "Running smoke tests with curl..."
            sh 'curl -v -X GET http://localhost:8091/status || echo "API /status endpoint failed!"'
            sh """
                curl -v -X POST 'http://localhost:8091/users/login' \\
                -H 'Content-Type: application/json' \\
                --data-raw '{"email":"customer@practicesoftwaretesting.com","password":"welcome01"}' || echo "API login endpoint failed!"
            """
        }
    }

    stage('Run Backend Tests') {
      steps {
        // Run tests directly on the agent, as PHPUnit/Pest are now accessible
        dir("${env.API_DIR}") {
          // You could add logic here similar to deploy.yml for pest/phpunit based on sprint
          sh './vendor/bin/pest' // Or './vendor/bin/phpunit' if you use Pest exclusively for sprint 5
        }
      }
    }

    stage('Run Frontend Tests') {
      steps {
        // This stage will now run Playwright tests from the agent, against the running Dockerized app
        // You might need additional Playwright setup on the agent if you haven't done it yet
        // (similar to how GHA installs browser binaries)
        dir("${env.UI_DIR}") { // Assuming playwright.config.ts and tests are in the UI directory
            // GHA uses 'npx playwright install-deps' and 'npx playwright test'
            // Your agent Dockerfile already installed node, npm.
            // You might need to add `npx playwright install --with-deps` to your agent Dockerfile
            // or run it here if you want to manage browser binaries per build.
            sh 'npx playwright test'
        }
      }
    }

    // You can potentially remove the 'Up and Ping' stage if 'Setup Test Environment' handles it.
    // I've incorporated the 'up -d' and curl checks into 'Setup Test Environment'.

  }

  post {
    always {
      // Ensure containers are brought down even if stages fail
      echo "Bringing down Docker services..."
      sh 'docker-compose down -v --remove-orphans' // Added --remove-orphans for good measure
    }

    failure {
      echo '❌ Build or tests failed!'
    }

    success {
      echo '✅ CI pipeline completed successfully!'
    }
  }
}