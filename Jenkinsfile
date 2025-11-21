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
                      -var="vpc_id=vpc-042437eaf1b20f768" \
                      -var="subnet_id=subnet-099653b9a674986d4" \
                      -var="key_name=ubuntu"
                    '''
                }
            }
        }

        stage('Configure Ansible Dynamic Inventory') {
            steps {
                sh '''
                cp ansible/ansible.cfg .
                '''
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sh '''
                ANSIBLE_CONFIG=./ansible/ansible.cfg ansible-playbook -i ansible/inventory/aws_ec2.yml ansible/site.yml
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
