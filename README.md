# FME Training Virtual Machines and Automation
The files in this repository are used to create virtual machines for FME training courses, and to allow students to request virtual machines on-demand.
The virtual machines are Amazon AWS EC2 machines.
The webpage used for requesting the virtual machines is a static page hosted on AWS S3.

## Prerequisites
A basic understanding of GitHub, Amazon AWS, FME Desktop, and FME Server is required.
You will also require an AWS account and a GitHub account.
On your local machine, you will need an installation of GitHub Desktop and FME Desktop.

Be aware that you'll probably have to request an Instance Limit increase for the EC2 instances. The default limit is 20 machines. At Safe Software, we have a limit of 500.

Also be aware that the default VPC limit is 5. If you currently have 5 VPCs in your desired region, you will have to request an increase in the VPC limit.

![EC2 Service Increase](/images/EC2Limits.png)

## Overview
1. Fork this Repository to your own account
1. Create and configure S3 Bucket for static webpage
1. Install and update AWSCredentialSupplier.fmx
1. Edit settings.json
1. Run QuickSetup.fmw
1. Create and tag AMI
1. Publish VMCreator.fmw and GitClone2S3.fmw with AWSCredentialSupplier.fmx to FME Server/Cloud
1. Configure GitHub webhook to run GitClone2s3.fmw


There are two files in the repository that need to be edited, and two workspaces that need to be edited and published to FME Server. The two files you will eventually edit are:
1. settings.json
1. InitialConfiguration.bat


# Steps
## Fork this Repository to your own account
Click Fork.
Once forked into your own account, click Settings.
Change the repository name if desired.
Create a branch that will be the name of the course.

## Create and configure S3 Bucket for static webpage
## Install and update AWSCredentialSupplier.fmx
## Edit settings.json
* Replace `password` with the desired login password for the virtual machine
* Replace `fmelicenseip` with the FME license server IP address

## Run QuickSetup.fmw
This step creates your AWS EC2 Environment
1. Open QuickSetup.fmw
1. Run Quicksetup.fmw

### Configure FlexNet License Server
1. Follow the instructions in the /workspaces/LicenseServerInfo.txt file to request a license.
1. Edit the safe.lic file so that the VENDOR line is 'VENDOR safe port=27010' and the serial number is removed.
1. Save the safe.lic file into your GitHub repository and push any updates.
1. Reboot the license server machine.

### Configure FME Server
1. Using the public IP address, log into FME Server. Username and password are `admin`
1. Change the admin password
1. Activate FME Server
1. Create FMETraining repository
1. Create token that can only Read and Run from the FMETraining repository

## Create and tag AMI
Once the machine is configured, create an image (AMI) and add a tag called `git.branch`. The course is the name of the image (like training, or certification). This tag is used by the VMCreator.fmw file to launch virtual machines on demand.  

## Publish VMCreator.fmw and GitClone2S3.fmw with AWSCredentialSupplier.fmx to FME Server/Cloud
1. Open VMCreator.fmw, set the private parameters `git.username` and `git.repository`, and add a webconnection for the `GMAIL_NAMED_CONNECTION` private parameter. Publish to the FMETraining repository on FME Server.

## Configure GitHub webhook to run GitClone2s3.fmw
1. Navigate to your GitHub repository
1. Click on the `Settings` tab
1. Click on `Webhooks`
1. Click `Add webhook`
1. Payload URL is `https://<server name>/fmejobsubmitter/<repository name>/GitHub2S3.fmw?GITUSER=<git user name>&GITREPOSITORY=<repository name>&GITBRANCH=<git branch>&S3_BUCKET_NAME=<S3 Bucket>&S3_OBJECT_KEY=<folder in bucket>&opt_showresult=true`
1. Content type is `application/json`


OnstartConfiguration.bat is run by the Task Scheduler on the virtual machines every time the virtual machine starts (or restarts). This allows you to perform additional configuration steps at startup.

## Creating additional courses
Fork the current GitHub branch, and give it a name that matches the Course tag on the AMI.

## Set Calendar Reminders
If you are not using a permanent license for FME Server, you'll have to re-license it on occasion. The FME Server token will also have to be refreshed.
