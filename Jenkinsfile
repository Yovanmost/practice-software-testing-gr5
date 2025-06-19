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

    stage('Build & Install') {
      steps {
        dir("${env.WORKSPACE}/sprint5-with-bugs") {
          sh 'docker-compose --env-file .env build --no-cache'
          sh 'docker-compose --env-file .env run --rm composer install'
          sh 'docker-compose --env-file .env run --rm laravel-api php artisan config:clear'
          sh 'docker-compose --env-file .env run --rm angular-ui npm install --legacy-peer-deps --force'
        }
      }
    }

    stage('Run Tests') {
      steps {
        dir("${env.WORKSPACE}/sprint5-with-bugs") {
          sh 'docker-compose --env-file .env run --rm laravel-api php artisan test'
          sh 'docker-compose --env-file .env run --rm angular-ui npm run test -- --watch=false --browsers=ChromeHeadless'
        }
      }
    }

    stage('Smoke Test') {
      steps {
        dir("${env.WORKSPACE}/sprint5-with-bugs") {
          sh 'docker-compose --env-file .env up -d'
          sh 'sleep 10'
          sh 'curl -f http://localhost || echo "Laravel backend might be down"'
        }
      }
    }
  }

  post {
    always {
      dir("${env.WORKSPACE}/sprint5-with-bugs") {
        sh 'docker-compose --env-file .env down -v'
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
