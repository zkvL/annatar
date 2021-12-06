# annatar

## Description
This project consists of some orchestration and configuration management scripts to deploy on-cloud infrastructure for web and mail servers and some tricks and tools to host phishing campaigns (always for educational purposes).

## Requirements
1. Install Terraform based on your platform:

- Mac with [Homebrew](https://brew.sh/index_es)
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

- Windows with [Chocolatey](https://chocolatey.org/install)
```
choco install terraform
```

- Linux (Ubuntu/Debian)
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

Verify the installation `terraform -help`

For more information on custom installations refer to the [official documentation](https://learn.hashicorp.com/terraform).

2. Install Ansible.

- Debian
```
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" >> /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
sudo apt update
sudo apt install ansible
```

- Ubuntu
```
sudo apt update
$ sudo apt install software-properties-common
$ sudo apt-add-repository --yes --update ppa:ansible/ansible
$ sudo apt install ansible
```

- Ansible with PIP
```
python -m pip install --user ansible paramiko 
```

For more information on custom installations refer to the [official documentation](https://docs.ansible.com/ansible/latest/index.html)

3. Configure Google Cloud Platform proyect.
- [Create a proyect on GCP](https://console.cloud.google.com/projectcreate) and save the name for later use.
- If [Compute Engine API](https://console.developers.google.com/apis/library/compute.googleapis.com) is not enabled, enable it; same with [Cloud DNS API.](https://console.developers.google.com/apis/api/dns.googleapis.com/)
- Create a GCP [service account key](https://console.cloud.google.com/apis/credentials/serviceaccountkey) and save it.
	- Select the project you created in the previous step.
	- Under "Service account", select "New service account".
	- Give it any name you like.
	- For the Role, choose "Project -> Editor".
	- Leave the "Key Type" as JSON.
	- Click "Create" to create the key and save the key file to your system.

## Deployment

In this section, I'll describe two possible use cases using Ansible roles with the infrastructure deployed by Terraform.

### Use case 1: Domain web hosting plus Gophish (mail service managed separately)

Let's say you need need to deploy a VPS with web hosting capabilities and Gophish on it. The hosting capabilities could help to create useful websites meanwhile Gophish can serve on its specific ports for phishing campaigns using an external mail service provider; such as Google Workspace. To do so, follow the next steps:

1. Buy a valid domain from whoever provider you want.
2. Deploy the infrastructure.

```
# Go to annatar/gcp/terraform and copy the generic-server terraform folder
cp -r generc-server webserver && cd webserver
terraform init
terraform apply \
	-var 'credentials_file=../credentials/gcp-key.json' \
	-var 'project=annatar' \
	-var 'instance_name=webserver' \
	-var 'hostname=example.mx' \
	-var 'username=myuser' \
	-var 'open_ports=["22","80","443","8080"]' \
	-var 'ssh_pubKey=~/.ssh/id_rsa.pub'
```

3. Create the DNS records for your domain within the cloud provider instance configuration. The DNS servers given by the output of this step need to be configured within your DNS Console from whoever your domain provider is.

```
# Go to annatar/gcp/terraform/domain-dns
terraform init
terraform apply \
	-var 'credentials_file=../credentials/gcp-key.json' \
	-var 'project=annatar' \
	-var 'instance_eip=10.11.12.13' \
	-var 'domain=example.mx'
```

> **NOTE** 
>
> - The variables used are just examples, adecuate 'em according to your own environment. Some of them can be omited and a default value will be used, review the `variables.tf` file as well.
>
> - You can change "***apply***" for "***plan***" or "***destroy***" to see what is going to be deployed or to remove the instance respectively.
>
> - MX record is set within the terraform setup, if you're going to use, for instance, Google Workspace it's easier for you to use the default Google DNS servers and its MX servers. So, do not pay attention to the DNS output from Terraform and instead manually configure the necessary records on your Domain Admin Console. 
>
>   **(A, MX, DMARC & SPF records)**

4. Verify your domain ownership.

- Open [Webmaster Central](https://www.google.com/webmasters/verification/home) and sign in using the Google Cloud account that you will use to add a PTR record to your instance. You can verify domain ownership with multiple accounts.
- Click Add a property.
- Enter the PTR domain name.
- Click Continue.
- Follow the instructions and click Verification Details.

5. Configure on GCP the rDNS PTR record.

```
curl -X POST https://compute.googleapis.com/compute/v1/projects/[PROJECT_ID]/zones/[ZONE]/instances/[INSTANCE_NAME]/updateAccessConfig?networkInterface=nic0 \
	-H "Content-Type: application/json" \
    -d "{\"setPublicPtr\": true,\"publicPtrDomainName\": \"[DOMAIN_NAME]\"}"
    -b "[COOKIES]"
```

Or you can do it through the [web interface](https://console.cloud.google.com/compute/instances)

 - Click the instance you want to edit.
   - Click the Edit tool from the top menu.
   - Click the edit tool next to the primary network interface.
   - Click External IP drop down menu.
   - Check the Enable box for Public DNS PTR Record.
   - Enter your domain name.
   - Click Done.
   - Click Save at the bottom of the page to save your settings.

6. Validate DNS records, probably you would need to wait for DNS replication.

- [SPF](https://app.dmarcanalyzer.com/dns/spf?simple=1) 
- Reverse and direct host resolution

```
dig +short A [DOMAIN_NAME]
dig +short MX [DOMAIN_NAME]
host [DOMAIN_NAME]
```

- [rDNS](https://mxtoolbox.com/ReverseLookup.aspx)
- [intodns](https://intodns.com/)
- [mxtoolbox](https://mxtoolbox.com/)

7. Go back to `annatar/gcp/`, update the `inventory` file with the username and IP address from step 2.

```
[webservers]
10.11.12.13     ansible_connection=ssh        ansible_user=myuser
```

8. There is already an example for webserver playbook in ` annatar.yml`edit the domain name inside this file accordingly and then execute:

```
ansible-playbook -i inventory --ask-become-pass annatar.yml
```

9. Now Gophish can be executed locally; login to the server with the IP and user from terraform deployment and execute `cd /opt/gophish/ && sudo ./gophish`

10. On the operator machine create a tunnel to access the Gophish interface through a SOCKS4 proxy. Remember to adecuate the values to your environment.

`ssh -f -N -D 127.0.0.1:8080 -p 22 myuser@10.11.12.13`

11. Set up the SOCKS4 proxy and access the web interface through localhost `https://127.0.0.1:3333/`.

12. Have fun with your campaign! Also your web hosting root is ready on `/var/www/html/example.mx`.

### Use case 2: Set up a mail service provider for your phishing campaigns

Now, what if you need some mailing capabilities, for phishing campaigns or just to be able to send mails with your custom domain. To do so, follow the next steps: 

1. You must already have a valid domain bought and deployed a web server for your domain; for instance by executing the [Use case 1](#Use-case-1:-Web-hosting-with-Gophish-only-(mail-service-managed-separately)) 
2. Deploy the infrastructure.

```
# Go to annatar/gcp/terraform and copy the generic-server terraform folder
cp -r generc-server mailserver && cd mailserver
terraform init
terraform apply \
	-var 'credentials_file=../credentials/gcp-key.json' \
	-var 'project=annatar' \
	-var 'instance_name=mailserver' \
	-var 'hostname=mail.example.mx' \
	-var 'username=myuser' \
	-var 'open_ports=["22","80","143","443","587","993"]' \
	-var 'ssh_pubKey=~/.ssh/id_rsa.pub'
```

> **NOTE** 
>
> - The variables used are just examples, adecuate 'em according to your own environment. Some of them can be omited and a default value will be used, review the `variables.tf` file as well.
> - You can change "***apply***" for "***plan***" or "***destroy***" to see what is going to be deployed or to remove the instance respectively.

3. Go to the [DNS Zone configuration](https://console.cloud.google.com/net-services/dns/zones/) and modify the A & SPF records for **mail.example.mx** to point to this instance. The IP address is given by the output from step 2. Also configure the [rDNS PTR record](https://console.cloud.google.com/compute/instances?) for **mail.example.mx**.

4. Go back to `annatar/gcp/`, update the `inventory `file with the username and IP address from step 2. 

```
[mailservers]
10.13.12.11  	ansible_connection=ssh        ansible_user=myuser

[mailservers:vars]
ansible_python_interpreter=/usr/bin/python
```

> **NOTE**
>
> Python2 is used since `community.mysql` does not work properly with the database manipulation and Python3 (at the time of this development)

5. There is already an example for mail server playbook in ` annatar.yml`edit the domain name inside this file accordingly and then execute:

```
# If community.mysql.mysql_db plugin is not installed:
ansible-galaxy collection install community.mysql

# Deploy mailserver configuration
ansible-playbook -i inventory --ask-become-pass -e "db_postfixadmin_pass=STRONGPASSWORD db_roundcubemail_pass=STRONGPASSWORD api-key=MAILJET_API_KEY
secret-key=MAILJET_SECRET_KEY" annatar.yml
```

> **NOTE**
>
> - Pay attention to the steps required during deployment, PostfixAdmin and Roundcubemail require some manual steps according to your specific needs.
> - Adjust the variables as needed

6. Have fun!

### Troubleshooting

If the error `Invalid query: Specified key was too long; max key length is 1000 bytes` arises when setting up postfixadmin setup password you need to manually log in to the server and change the database default collation.

```
sudo mysql -u root
alter database postfixadmin collate ='utf8_general_ci';
```

Then go back to the web interface and refresh.

## Considerations
Currently, these scripts have support for [Google Cloud Platform](https://console.cloud.google.com); aditional cloud providers will be added on time. 

Also **do not forget to perform necessary validations before sending mails** and don't forget to categorize and give some reputation to your domain.

- Send an empty mail to check-auth@verifier.port25.com and wait for the response
- On the response, validate if the SPF and DKIM registries are right
- Validate the DNS registry in [dkim-ckecker](https://protodave.com/tools/dkim-key-checker/) or [dkimcore](http://dkimcore.org/c/keycheck)
- Validate the mail with [dkimvalidator](http://dkimvalidator.com/)
- Try the whole configuration with [mail tester](https://www.mail-tester.com/)

Remember that making a 10/10 within mail-tester does not assure that mails will make it to the inbox of our recipient. There are other things to take into consideration. You can read more about it [here.](https://www.linuxbabe.com/mail-server/how-to-stop-your-emails-being-marked-as-spam)

## Other automated solutions

You can also try these solutions, some of the taks from this ansible roles are based on they,

- [iRedMail](https://www.linuxbabe.com/mail-server/debian-10-buster-iredmail-email-server)
- [Modoba](https://www.linuxbabe.com/mail-server/email-server-ubuntu-18-04-modoboa)

Also, feel free to replicate yourself the mail server set up so you can understand each component and their function.

- [Ubuntu mail server](https://www.linuxbabe.com/mail-server/setup-basic-postfix-mail-sever-ubuntu)

## Author & Acknowlegments
author: [Yael](https://twitter.com/zkvL_)

All the references above helped to deploy these scripts and was a great exercise for me to start automating stuff with orchestration and config management. If you find things to improve on coding, organization, or anything else I'll be happy to know about it. 
