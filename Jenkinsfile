pipeline {
  agent {
    node {
      label 'my-jenkins-agent'
    }
  }

  environment {
    COMPOSE_FILE = 'docker-compose.yml'
    SPRINT_FOLDER = 'sprint5-with-bugs'
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
        sh 'docker-compose build --no-cache'
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'docker-compose run --rm composer install'
        sh 'docker-compose run --rm laravel-api php artisan config:clear'
        sh 'docker-compose run --rm angular-ui npm install --legacy-peer-deps --force'
      }
    }

    stage('Run Backend Tests') {
      steps {
        sh 'docker-compose run --rm laravel-api php artisan test'
      }
    }

    stage('Run Frontend Tests') {
      steps {
        sh 'docker-compose run --rm angular-ui npm run test -- --watch=false --browsers=ChromeHeadless'
      }
    }

    stage('Lint (Optional)') {
      steps {
        // Optional linting commands
      }
    }

    stage('Up and Ping (Optional Smoke Test)') {
      steps {
        sh 'docker-compose up -d'
        sh 'sleep 10'
        sh 'curl -f http://localhost || echo "Laravel backend might be down"'
      }
    }
  }

  post {
    always {
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
