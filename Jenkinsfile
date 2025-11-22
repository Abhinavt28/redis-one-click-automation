pipeline {
    agent any

    environment {
        TF_WORKING_DIR = "terraform"
        ANSIBLE_DIR    = "ansible"
        KEY_FILE       = "${env.HOME}/.ssh/${KEY_NAME}.pem"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                echo "Skipping cleanWs for first run"
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Abhinavt28/redis-one-click-automation.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform init -migrate-state -force-copy
                """
            }
        }

        stage('Terraform Plan') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform plan -out=tfplan -input=false -var="key_name=${KEY_NAME}"
                """
            }
        }

        stage('Terraform Apply') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform apply -auto-approve -input=false tfplan
                """
            }
        }

        stage('Wait For EC2 Boot') {
            steps {
                echo "Waiting 30 seconds for bastion & Redis instances to be ready…"
                sh "sleep 30"
            }
        }

        stage('Configure Redis Using Ansible') {
    steps {
        sh """
           cd ${ANSIBLE_DIR}

ansible-galaxy collection install -r requirements.yml

BASTION_IP=$(terraform -chdir=../terraform output -raw bastion_public_ip)

export ANSIBLE_SSH_ARGS="-o ProxyCommand='ssh -W %h:%p ubuntu@${BASTION_IP} -i ${KEY_FILE}'"

ansible-inventory -i inventory/aws_ec2.yml --graph

ansible-playbook -i inventory/aws_ec2.yml site.yml

        """
    }
}


    post {
        success {
            echo "🚀 Redis Master + Replica Deployment SUCCESS!"
        }
        failure {
            echo "❌ Deployment Failed. Check console output."
        }
    }
}
