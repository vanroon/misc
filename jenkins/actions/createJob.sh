#!/bin/bash 

usage() {
	echo "Create multibranch pipeline on Jenkins"
	echo "Params:"
	# TODO
	# replace job config.xml value of '<remote>' tag with passed value of -g git repo
	echo " - g git repo (ssh url)"
	echo " - j jenkinsUrl e.g. \"http://127.0.0.1"
	echo " - n jenkinsPort e.g. 8080" 
	echo " - u username"
	echo " - p password"
}

while getopts ":g:j:n:u:p:" o; do
		case "${o}" in
				g)
						gitrepo=${OPTARG}
						;;
				j)
						jenkinsUrl=${OPTARG}
						;;
			    n)
						jenkinsPort=${OPTARG}
						;;
				u)
						username=${OPTARG}
						;;
				p)
						password=${OPTARG}
						;;
		esac
done
shift $((OPTIND -1))

if [[ -z ${gitrepo} ]] || [[ -z ${jenkinsUrl} ]] || [[ -z ${username} ]] || [[ -z ${password} ]];then
		echo "please check parameters"
		usage
fi

# Create job config.xml
# 1. locate template config.xml
# 2. Replace value of <remote> tag
# 3. Replace other values? e.g. credentialsId, sciptPath, 
# 4. Run script (w/ ansible?)

# Get crumb:
USERNAME=${username}
PASSWORD=${password}
JENKINS_URL=${jenkinsUrl}
PORT=${jenkinsPort}
JOB_NAME="jobName"

echo ${JENKINS_URL}
echo ${USERNAME}

JENKINS_CRUMB=$(wget -q --auth-no-challenge --user ${USERNAME} --password ${PASSWORD} --output-document - "${JENKINS_URL}:${PORT}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
echo $JENKINS_CRUMB

curl -s XPOST "${JENKINS_URL}:${PORT}/createItem?name=${JOB_NAME}" -u ${USERNAME}:${PASSWORD} -H "${JENKINS_CRUMB}" --data-binary @/tmp/localconfig.xml -H "Content-Type:text/xml"
