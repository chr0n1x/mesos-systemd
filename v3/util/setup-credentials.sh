#!/usr/bin/bash -xe

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOMEDIR=$(eval echo "~`whoami`")
OWNER=$(whoami)

source /etc/environment

TABLE=`sudo echo $SECRETS_TABLE`
docker pull behance/docker-aws-secrets-downloader:latest

# Create a dockercfg
DOCKERCFG_CONTENTS=`sudo docker run behance/docker-aws-secrets-downloader --table $TABLE --key secrets --name DOCKERCFG --format plain`
echo "$DOCKERCFG_CONTENTS" > /home/${OWNER}/.dockercfg
sudo chown -R ${OWNER}:${OWNER} /home/${OWNER}/.dockercfg
sudo cp /home/${OWNER}/.dockercfg /root/.dockercfg

# ensure that we have a public key for our RSA key and that it's authorized
if [ -f ${HOMEDIR}/.ssh/id_rsa ]; then
    ssh-keygen -f ${HOMEDIR}/.ssh/id_rsa -y > ${HOMEDIR}/.ssh/id_rsa.pub
    cat ${HOMEDIR}/.ssh/id_rsa.pub >> ${HOMEDIR}/.ssh/authorized_keys
fi

# Save the RDS password to environment variable in control tier
# TODO: :(
if [[ "$NODE_ROLE" = "control" && $AV_SECRETS == *"RDSPASSWORD"* ]]; then
    RDSPASSWORD=`sudo docker run behance/docker-aws-secrets-downloader --table $TABLE --key secrets --name RDSPASSWORD --format plain`
    etcdctl set /environment/RDSPASSWORD $RDSPASSWORD
fi

# ignore requests against github.com
# TODO: maybe...re-evaluate this
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" > ${HOMEDIR}/.ssh/config
