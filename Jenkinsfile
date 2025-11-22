pipeline {
    agent any

    environment {
        TF_WORKING_DIR = "terraform"
        ANSIBLE_DIR = "ansible"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform init -input=false
                """
            }
        }

        stage('Terraform Plan') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform plan -out=tfplan -input=false
                """
            }
        }

        stage('Terraform Apply') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform apply -input=false -auto-approve tfplan
                """
            }
        }

        stage('Wait For EC2 Boot') {
            steps {
                echo "Waiting 30 seconds for bastion + redis instances to fully boot..."
                sh "sleep 30"
            }
        }

        stage('Configure Redis (Ansible)') {
            steps {
                sh """
                    cd ${ANSIBLE_DIR}

                    # Fetch Bastion IP dynamically from terraform state
                    BASTION_IP=\$(terraform -chdir=../terraform output -raw bastion_public_ip)

                    export ANSIBLE_SSH_ARGS="-o ProxyCommand='ssh -W %h:%p ubuntu@\$BASTION_IP -i ~/.ssh/${KEY_NAME}.pem'"

                    ansible-playbook -i inventory/aws_ec2.yml site.yml
                """
            }
        }

    }

    post {
        success {
            echo "🚀 Redis Master + Replica Deployment Successful!"
        }
        failure {
            echo "❌ Deployment Failed — Please check logs!"
        }
    }
}
