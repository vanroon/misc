FROM jenkins/jenkins:lts

RUN mkdir /var/jenkins_home/init.groovy.d/
COPY /home/evroon/Development/misc/Dockerfiles/Jenkins/config/initPlugins.sh /var/jenkins_home/init.groovy.d/installPlugins.sh
