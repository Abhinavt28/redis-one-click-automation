pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        TF_DIR     = "terraform"
        ANS_DIR    = "ansible"

        BASTION_KEY = "/var/lib/jenkins/.ssh/ubuntu.pem"
        JENKINS_KEY = "/var/lib/jenkins/.ssh/ubuntu"
    }

    stages {

        stage('Clean Workspace') {
            steps { cleanWs() }
        }

        stage('Checkout Repo') {
            steps {
                git url: 'https://github.com/Abhinavt28/redis-one-click-automation.git',
                    branch: 'main',
                    credentialsId: 'github-creds'
            }
        }

        stage('Fix SSH known_hosts') {
            steps {
                sh '''
                rm -f /var/lib/jenkins/.ssh/known_hosts
                touch /var/lib/jenkins/.ssh/known_hosts
                chmod 600 /var/lib/jenkins/.ssh/known_hosts
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                cd ${TF_DIR}
                terraform init
                terraform apply -auto-approve
                '''
            }
        }

        stage('Wait') {
            steps { sh "sleep 40" }
        }

        stage('Run Ansible') {
            steps {
                sh '''
                cd ${ANS_DIR}

                ansible-galaxy collection install -r requirements.yml

                BASTION=$(terraform -chdir=../${TF_DIR} output -raw bastion_public_ip)
                echo "BASTION IP: $BASTION"

                export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no -o ProxyCommand=\\"ssh -W %h:%p -i ${BASTION_KEY} ubuntu@$BASTION\\""

                ansible-inventory -i inventory/aws_ec2.yml --graph

                ansible-playbook -i inventory/aws_ec2.yml site.yml
                '''
            }
        }
    }

    post {
        success { echo "Redis Deploy Successful!" }
        failure { echo "Deployment Failed!" }
    }
}
