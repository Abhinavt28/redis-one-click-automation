pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Abhinavt28/redis-one-click-automation.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh '''
                    terraform apply -auto-approve \
                      -var="vpc_id=vpc-03bdb5ce605d44e8d" \
                      -var="subnet_id=subnet-099653b9a674986d4" \
                      -var="key_name=ubuntu"
                    '''
                }
            }
        }

        stage('Configure Ansible Dynamic Inventory') {
            steps {
                sh '''
                sudo mkdir -p /etc/ansible
                sudo cp ansible/ansible.cfg /etc/ansible/
                '''
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sh '''
                ansible-playbook -i ansible/inventory/aws_ec2.yml ansible/site.yml
                '''
            }
        }
    }

    post {
        success {
            echo "Redis One-Click Automation Completed Successfully!"
        }
        failure {
            echo "Build Failed. Check logs."
        }
    }
}
