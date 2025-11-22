pipeline {
    agent any

    environment {
        TF_WORKING_DIR = "terraform"
        ANSIBLE_DIR    = "ansible"
        KEY_FILE       = "/var/lib/jenkins/.ssh/ubuntu.pem"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Abhinavt28/redis-one-click-automation.git',
                    credentialsId: 'github-creds'
            }
        }

        stage('Fix SSH known_hosts') {
            steps {
                sh '''
                    echo "Cleaning Jenkins SSH known_hosts..."
                    rm -f ~/.ssh/known_hosts || true
                    touch ~/.ssh/known_hosts
                    chmod 600 ~/.ssh/known_hosts
                '''
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
                    terraform plan -out=tfplan
                """
            }
        }

        stage('Terraform Apply') {
            steps {
                sh """
                    cd ${TF_WORKING_DIR}
                    terraform apply -auto-approve tfplan
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
                sh '''
                    cd ansible

                    echo "Installing AWS collection..."
                    ansible-galaxy collection install -r requirements.yml

                    echo "Fetching Bastion IP..."
                    BASTION_IP=$(terraform -chdir=../terraform output -raw bastion_public_ip)
                    echo "Bastion IP = $BASTION_IP"

                    # Set ProxyCommand via bastion
                    export ANSIBLE_SSH_ARGS="-o ProxyCommand=\\"ssh -W %h:%p ubuntu@$BASTION_IP -i /var/lib/jenkins/.ssh/ubuntu.pem\\""

                    echo "Testing inventory..."
                    ansible-inventory -i inventory/aws_ec2.yml --graph

                    echo "Running Ansible playbook..."
                    ansible-playbook -i inventory/aws_ec2.yml site.yml
                '''
            }
        }
    }

    post {
        success {
            echo "🚀 Redis Master + Replica Deployment SUCCESS!"
        }
        failure {
            echo "❌ Deployment FAILED — Check logs."
        }
    }
}
