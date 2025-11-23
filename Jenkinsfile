pipeline {
    agent any

    environment {
        AWS_REGION    = "us-east-1"
        TF_WORKDIR    = "terraform"
        ANS_WORKDIR   = "ansible"
        BASTION_KEY   = "/var/lib/jenkins/.ssh/ubuntu.pem"
        JENKINS_KEY   = "/var/lib/jenkins/.ssh/ubuntu"
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
                    echo "Resetting known_hosts..."
                    rm -f /var/lib/jenkins/.ssh/known_hosts
                    touch /var/lib/jenkins/.ssh/known_hosts
                    chmod 600 /var/lib/jenkins/.ssh/known_hosts
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh '''
                    cd ${TF_WORKDIR}
                    terraform init -migrate-state -force-copy
                    terraform apply -auto-approve
                '''
            }
        }

        stage('Wait for EC2 Boot') {
            steps {
                sh 'sleep 60'
            }
        }

        stage('Configure Redis via Ansible') {
            steps {
                sh '''
                    cd ${ANS_WORKDIR}

                    echo "Installing AWS collections..."
                    ansible-galaxy collection install -r requirements.yml

                    echo "Fetching Bastion Public IP..."
                    BASTION_IP=$(terraform -chdir=../${TF_WORKDIR} output -raw bastion_public_ip)
                    echo "BASTION IP = $BASTION_IP"

                    echo "Setting SSH Proxy for Ansible..."
                    export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no -o ProxyCommand=\\"ssh -o StrictHostKeyChecking=no -W %h:%p -i ${BASTION_KEY} ubuntu@${BASTION_IP}\\""

                    echo "Inventory Check..."
                    ansible-inventory -i inventory/aws_ec2.yml --graph

                    echo "Running Ansible..."
                    ansible-playbook -i inventory/aws_ec2.yml site.yml --private-key=${JENKINS_KEY}
                '''
            }
        }
    }

    post {
        success {
            echo "🚀 Redis Deployed Successfully — Master + Replica LIVE!"
        }
        failure {
            echo "❌ Deployment Failed — Check Logs!"
        }
    }
}
