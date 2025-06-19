pipeline {
  agent {
    node {
      label 'my-jenkins-agent'
    }
  }

  environment {
    SPRINT_FOLDER = 'sprint5-with-bugs'
    DISABLE_LOGGING = 'true'
    DOCKER_HOST = "tcp://docker-tcp-relay:2375"
  }

  options {
    skipStagesAfterUnstable()
  }

  triggers {
    pollSCM('* * * * *') // You can change this to `githubPush()` if using GitHub integration
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Start Services') {
      steps {
        sh '''
          docker-compose -f docker-compose.yml --env-file .env up -d --build
        '''
      }
    }

    stage('Wait for Containers') {
      steps {
        echo 'Sleeping for 60s to allow containers to initialize...'
        sh 'sleep 60'
      }
    }

    stage('Run Laravel Migrations & Seed') {
      steps {
        sh '''
          docker-compose exec -T laravel-api php artisan migrate:fresh --seed
        '''
      }
    }

    stage('Run Laravel Tests (Pest)') {
      steps {
        sh '''
          docker-compose exec -T laravel-api ./vendor/bin/pest
        '''
      }
    }

    stage('Run Playwright Tests') {
      steps {
        dir("${env.SPRINT_FOLDER}/UI") {
          sh '''
            npm ci
            npx playwright install --with-deps
            npx playwright test
          '''
        }
      }
    }
  }

  post {
    always {
      echo 'Cleaning up containers...'
      sh 'docker-compose down'
    }
  }
}
