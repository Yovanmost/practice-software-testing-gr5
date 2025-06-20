pipeline {
  agent {
    node {
      label 'my-jenkins-agent'
    }
  }

  environment {
    COMPOSE_FILE = 'docker-compose.yml'
    DOCKER_HOST = "tcp://docker-tcp-relay:2375"
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
        // Confirm we are in the correct directory for docker-compose
        dir('practice-ci') {
          sh 'pwd' // Confirm current working directory
          sh 'ls -l' // List contents of practice-ci to see docker-compose.yml and sprint5-with-bugs
          sh 'docker-compose build --no-cache'
        }
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('practice-ci') {
          // Confirm composer.json is visible from the Jenkins agent's perspective
          sh 'ls -l sprint5-with-bugs/API/composer.json || echo "composer.json NOT FOUND in JENKINS WORKSPACE"'

          // --- ADDED DEBUGGING STEPS ---
          echo "Attempting to run composer install and debug inside the container..."
          // Inspect the contents of /var/www *inside the composer container*
          sh 'docker-compose run --rm composer ls -al /var/www'
          // Try to specifically cat the composer.json file inside the container
          sh 'docker-compose run --rm composer cat /var/www/composer.json || echo "composer.json not accessible inside composer container"'
          // --- END ADDED DEBUGGING STEPS ---

          sh 'docker-compose run --rm composer install'
          sh 'docker-compose run --rm laravel-api php artisan config:clear'

          // 🔍 Check if vendor/ and composer.lock exist inside /var/www
          sh 'docker-compose run --rm laravel-api ls -al /var/www'
          sh 'docker-compose run --rm laravel-api ls -al /var/www/vendor || echo "vendor/ not found"'

          sh 'docker-compose run --rm angular-ui npm install --legacy-peer-deps --force'

          // 🔍 Check node_modules and dist
          sh 'docker-compose run --rm angular-ui ls -al /app'
          sh 'docker-compose run --rm angular-ui ls -al /app/node_modules || echo "node_modules/ not found"'
        }
      }
    }

    stage('Run Backend Tests') {
      steps {
        dir('practice-ci') {
          sh 'docker-compose run --rm laravel-api php artisan test'
        }
      }
    }

    stage('Run Frontend Tests') {
      steps {
        dir('practice-ci') {
          sh 'docker-compose run --rm angular-ui npm run test -- --watch=false --browsers=ChromeHeadless'
        }
      }
    }

    stage('Up and Ping (Optional Smoke Test)') {
      steps {
        dir('practice-ci') {
          sh 'docker-compose up -d'
          sh 'sleep 10'
          sh 'curl -f http://localhost || echo "Laravel backend might be down"'
        }
      }
    }
  }

  post {
    always {
      dir('practice-ci') {
        sh 'docker-compose down -v'
      }
    }

    failure {
      echo '❌ Build or tests failed!'
    }

    success {
      echo '✅ CI pipeline completed successfully!'
    }
  }
}