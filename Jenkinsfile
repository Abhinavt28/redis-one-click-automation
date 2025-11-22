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
                echo "Waiting 30 seconds for servers to be ready…"
                sh "sleep 30"
            }
        }

        stage('Configure Redis Using Ansible') {
    steps {
        sh """
            cd ${ANSIBLE_DIR}

            # Install the AWS inventory plugin
            ansible-galaxy collection install -r requirements.yml

            # Get bastion IP from terraform
            BASTION_IP=\$(terraform -chdir=../terraform output -raw bastion_public_ip)

            echo "Using Bastion IP: \$BASTION_IP"

            # Proxy to access private subnets through Bastion Host
            export ANSIBLE_SSH_ARGS="-o ProxyCommand='ssh -W %h:%p ubuntu@\$BASTION_IP -i ${KEY_FILE}'"

            # Debug inventory
            ansible-inventory -i inventory/aws_ec2.yml --graph

            # Run playbook
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
