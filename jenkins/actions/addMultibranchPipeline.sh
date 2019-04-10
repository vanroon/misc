#!/bin/bash 

usage() {
	echo "Create multibranch pipeline on Jenkins"
	echo "Params:"
	echo " - g git repo (ssh url)"
	echo " - j jenkinsUrl e.g. \"http://127.0.0.1\" (include double quotes)"
	echo " - n jenkinsPort e.g. 8080" 
	echo " - u username"
	echo " - p password"
	echo
	echo "--- Example ---"
	echo "Have txt file with repositories"
	echo "Loop through this file and call this this script:"
	echo 
	echo "for repo in \$(cat repolist.txt); do sh addMultibranchPipeline.sh -g \${repo} ...other params..."
	echo 
}

# GLOBAL VARS
DEFAULT_CONFIGXML="$(pwd)/config-default.xml"
CREDENTIALS_ID="BitBucket"
GITREMOTE_BASE="ssh://git@bitbucket.devoteam.nl:7999/dp/"

getJenkinsCrumb() {
		# IN: Username & password and Jenkins server
		# OUT: Valid Jenkins crumb (CSRF protection token) as an HTTP request header
	
		JENKINS_CRUMB=$(wget -q \
			--auth-no-challenge \
			--user ${USERNAME} \
			--password ${PASSWORD} \
			--output-document - \
			"${JENKINS_URL}:${PORT}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
		echo $JENKINS_CRUMB
}

createMBPipelineConfigXml() {
		# IN: default config.xml
		# IN: remote Repository
		# IN: credentialsId
		# OUT: Customized config.xml

		defaultConfig=${DEFAULT_CONFIGXML}
		# Create temporary file
		tmpfile=$(mktemp tmp-config.XXXXX.xml)
		exec 3>"$tmpfile"

		REMOTE="${GITREMOTE_BASE}${GIT_REPO_NAME}.git"

		sed "s|@@remote@@|${REMOTE}|g" ${DEFAULT_CONFIGXML} > "$tmpfile"
		sed -i "s|@@credentialsId@@|${CREDENTIALS_ID}|g" "$tmpfile"

		#cat "${tmpfile}"
}

postMBPipeline () {
		curl -s X POST \
		-u ${USERNAME}:${PASSWORD} \
		-H "${JENKINS_CRUMB}" \
		--data-binary @"${tmpfile}" \
		-H "Content-Type:text/xml" \
		"${JENKINS_URL}:${PORT}/createItem?name=${GIT_REPO_NAME}"
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
		exit 1
fi

USERNAME=${username}
PASSWORD=${password}
JENKINS_URL=${jenkinsUrl}
PORT=${jenkinsPort}
JOB_NAME="jobName"
GIT_REPO_NAME=${gitrepo}

getJenkinsCrumb
createMBPipelineConfigXml
postMBPipeline


# Remove tmp file
rm "$tmpfile"
