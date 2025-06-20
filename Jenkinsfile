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
        // No dir('practice-ci') needed here.
        // Commands run directly in /home/jenkins/workspace/practice-ci
        sh 'pwd' // Confirm current working directory
        sh 'ls -l' // List contents of the workspace root
        sh 'cat docker-compose.yml' // <-- ADD THIS LINE
        sh 'docker-compose build --no-cache'
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'ls -l sprint5-with-bugs/API/composer.json || echo "composer.json NOT FOUND in JENKINS WORKSPACE"'

        echo "Attempting to run composer install and debug inside the container..."

        sh 'docker-compose run --rm laravel-api composer install'
        sh 'docker-compose run --rm laravel-api php artisan config:clear'

        sh 'docker-compose run --rm laravel-api ls -al /var/www'
        sh 'docker-compose run --rm laravel-api ls -al /var/www/vendor || echo "vendor/ not found"'

        sh 'docker-compose run --rm angular-ui npm install --legacy-peer-deps --force'
        sh 'docker-compose run --rm angular-ui ls -al /app'
        sh 'docker-compose run --rm angular-ui ls -al /app/node_modules || echo "node_modules/ not found"'
      }
    }


    stage('Run Backend Tests') {
      steps {
        // No dir('practice-ci') needed here.
        sh 'docker-compose run --rm laravel-api php artisan test'
      }
    }

    stage('Run Frontend Tests') {
      steps {
        // No dir('practice-ci') needed here.
        sh 'docker-compose run --rm angular-ui npm run test -- --watch=false --browsers=ChromeHeadless'
      }
    }

    stage('Up and Ping (Optional Smoke Test)') {
      steps {
        // No dir('practice-ci') needed here.
        sh 'docker-compose up -d'
        sh 'sleep 10'
        sh 'curl -f http://localhost || echo "Laravel backend might be down"'
      }
    }
  }

  post {
    always {
      // No dir('practice-ci') needed here.
      sh 'docker-compose down -v'
    }

    failure {
      echo '❌ Build or tests failed!'
    }

    success {
      echo '✅ CI pipeline completed successfully!'
    }
  }
}