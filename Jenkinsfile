pipeline {
    agent {
        kubernetes {
            namespace 'yjlee'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-agent
  containers:
    - name: maven
      image: maven:3.9-eclipse-temurin-21
      command: ['cat']
      tty: true
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ['/busybox/cat']
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
    - name: kubectl
      image: registry.k8s.io/kubectl:v1.29.0
      command: ['cat']
      tty: true
  volumes:
    - name: docker-config
      secret:
        secretName: dockerhub-regcred
        items:
          - key: .dockerconfigjson
            path: config.json
"""
        }
    }

    triggers {
        pollSCM('H/3 * * * *')
    }

    environment {
        IMAGE_NAME = "hey880/spring-server"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/hey880/springhello.git'
            }
        }

        stage('Build Spring Boot') {
            steps {
                container('maven') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Kaniko Build & Push') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context `pwd` \
                            --dockerfile `pwd`/Dockerfile \
                            --destination=${IMAGE_NAME}:${IMAGE_TAG} \
                            --destination=${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Kubernetes Deploy') {
            steps {
                container('kubectl') {
                    sh """
                        sed "s|__IMAGE_TAG__|${IMAGE_TAG}|g" k8s/deployment.yaml > k8s/deployment-rendered.yaml

                        kubectl apply -f k8s/deployment-rendered.yaml -n yjlee
                        kubectl apply -f k8s/service.yaml -n yjlee

                        kubectl rollout status deployment/yeji-deployment-practice -n yjlee --timeout=120s
                    """
                }
            }
        }
    }

    post {
        failure {
            echo '파이프라인 실패!'
        }
    }
}