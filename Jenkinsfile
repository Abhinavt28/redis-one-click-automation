pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        TF_WORKDIR = "terraform"
        ANS_WORKDIR = "ansible"
        BASTION_SSH_KEY = "/var/lib/jenkins/.ssh/ubuntu.pem"   // AWS EC2 keypair
        PRIVATE_SSH_KEY = "/var/lib/jenkins/.ssh/ubuntu"       // Jenkins keypair (ubuntu / ubuntu.pub)
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
                terraform plan -out=tfplan
                terraform apply -auto-approve tfplan
                '''
            }
        }

        stage('Wait For EC2 Boot') {
            steps {
                // thoda time do instances ko boot hone ke liye
                sh 'sleep 60'
            }
        }

        stage('Configure Redis Using Ansible') {
            steps {
                sh '''
                cd ${ANS_WORKDIR}

                echo "Installing AWS collection..."
                ansible-galaxy collection install -r requirements.yml

                echo "Fetching Bastion IP from Terraform..."
                BASTION_IP=$(terraform -chdir=../${TF_WORKDIR} output -raw bastion_public_ip)
                echo "Bastion IP = ${BASTION_IP}"

                # ProxyCommand: Jenkins -> Bastion (using ubuntu.pem)
                export ANSIBLE_SSH_ARGS="-o ProxyCommand=\\"ssh -W %h:%p -i ${BASTION_SSH_KEY} ubuntu@${BASTION_IP}\\""

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
