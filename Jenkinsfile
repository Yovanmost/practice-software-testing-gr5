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

    stage('Debug ENV') {
      steps {
        sh 'cat .env || echo "No .env file found"'
        sh 'echo "SPRINT_FOLDER is set to: $(grep SPRINT_FOLDER .env | cut -d= -f2)" || echo "Not set"'
      }
    }

    stage('Build Services') {
      steps {
        sh 'docker-compose --env-file .env build --no-cache'
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'docker-compose --env-file .env run --rm composer install'
        sh 'docker-compose --env-file .env run --rm laravel-api php artisan config:clear'
        sh 'docker-compose --env-file .env run --rm angular-ui npm install --legacy-peer-deps --force'
      }
    }

    stage('Run Backend Tests') {
      steps {
        sh 'docker-compose --env-file .env run --rm laravel-api php artisan test'
      }
    }

    stage('Run Frontend Tests') {
      steps {
        sh 'docker-compose --env-file .env run --rm angular-ui npm run test -- --watch=false --browsers=ChromeHeadless'
      }
    }

    stage('Up and Ping (Optional Smoke Test)') {
      steps {
        sh 'docker-compose --env-file .env up -d'
        sh 'sleep 10'
        sh 'curl -f http://localhost || echo "Laravel backend might be down"'
      }
    }
  }

  post {
    always {
      sh 'docker-compose --env-file .env down -v'
    }

    failure {
      echo '❌ Build or tests failed!'
    }

    success {
      echo '✅ CI pipeline completed successfully!'
    }
  }
}
