#!/bin/bash -e

params=`getopt -o ds:n:i:p:e:m:u: -l dry-run,server:,name:,ip:,port:,executors:,mode:,user:,home:,creds:,desc:,labels: -- "$@"`

function usage()
{
    echo "Usage $0: options" 	
    echo "		[-d|--dry-run]"
    echo "		[-s|--server] jenkins_server"
    echo "		[-n|--name] node-name"
    echo "		[-i|--ip] node-ip (default: use node-name url)"
    echo "		[-p|--port] node-port (default 22)"
    echo "		[-e|--executors] nr_executors (default 1)"
    echo "		[-m|--mode] {NORMAL|EXCLUSIVE} (default NORMAL)"
    echo "		[-u|--user] node-user (default jenkins)"
    echo "		[--home] node-home(/home/jenkins)"
    echo "		[--creds] node-creds_id"
    echo "		[--desc] node-description"
    echo "		[--labels] node-labels"
    exit 1
}


if [ $? -ne 0 ]
then
    echo TRAP1
    usage
fi


# Note the quotes around `$TEMP': they are essential!
eval set -- "$params"
unset params

while true
do
    case $1 in
	-d|--dry-run)
	    DRY_RUN=1
	    shift
	    ;;
	-s|--server)
	    JENKINS_URL="$2"
	    shift 2
	    ;;
	-n|--name)
	    NODE_NAME="$2"
	    shift 2
	    ;;
	-i|--IP)
	    NODE_IP="$2"
	    shift 2
	    ;;
	-p|--port)
	    NODE_PORT="$2"
	    shift 2
	    ;;
	-e|--executors)
	    NODE_EXECUTORS="$2"
	    shift 2
	    ;;
	-m|--mode)
	    NODE_MODE="$2"
	    shift 2
	    ;;
	-u|--user)
	    NODE_USER="$2"
	    shift 2
	    ;;
	--home)
	    NODE_HOME="$2"
	    shift 2
	    ;;
	--creds)
	    CREDS_ID="$2"
	    shift 2
	    ;;
	--desc)
	    NODE_DESC="$2"
	    shift 2
	    ;;
	--labels)
	    LABELS="$2"
	    shift 2
	    ;;
	--)
	    shift
	    break
	    ;;
        *)
	    echo Unknown option: $1
            usage
            ;;
    esac
done

if [ -z "$JENKINS_URL" ]; then
    echo server required
    usage
fi
if [ -z "$NODE_NAME" ]; then
    echo node name required
    usage
fi

if [ -z "$NODE_IP" ]; then
    NODE_IP="$NODE_NAME"
fi
if [ -z "$NODE_PORT" ]; then
    NODE_PORT=22
fi

if [ -z "$NODE_MODE" ]; then
    NODE_MODE="NORMAL"
fi

if [ -z "$NODE_USER" ]; then
    NODE_MODE="jenkins"
fi

if [ -z "$NODE_HOME" ]; then
    NODE_MODE="/home/jenkins"
fi

if [ -z "$CREDS_ID" ]; then
    echo creds_id required
    usage
fi
##DRY_RUN=1
##JENKINS_URL="$2"
##NODE_NAME="$2"
##NODE_IP="$2"
##NODE_PORT="$2"
##NODE_EXECUTORS="$2"
##NODE_MODE="$2"
##NODE_USER="$2"
##NODE_HOME="$2"
##CREDS_ID="$2"
##NODE_DESC="$2"
##LABELS="$2"

config=`mktemp  /tmp/node-config-XXX.xml`

cat <<EOF > $config
<?xml version='1.0' encoding='UTF-8'?>
<slave>
  <name>${NODE_NAME}</name>
  <description>${NODE_DESC}</description>
  <remoteFS>${NODE_HOME}</remoteFS>
  <numExecutors>${NODE_EXECUTORS}</numExecutors>
  <mode>${NODE_MODE}</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.11">
    <host>${NODE_IP}</host>
    <port>${NODE_PORT}</port>
    <credentialsId>${CREDS_ID}</credentialsId>
    <maxNumRetries>0</maxNumRetries>
    <retryWaitTime>0</retryWaitTime>
  </launcher>
  <label>${LABELS}</label>
  <nodeProperties/>
</slave>
EOF


if [ -z "$DRY_RUN" ]; then
    cat $config | jenkins-cli -s $JENKINS_URL create-node $NODE_NAME
    jenkins-cli -s $JENKINS_URL online-node $NODE_NAME
else
    echo "DRY-RUN: cat $config | jenkins-cli -s $JENKINS_URL create-node $NODE_NAME"
    echo "DRY-RUN: jenkins-cli -s $JENKINS_URL online-node $NODE_NAME"
    echo "DRY-RUN: dump config $config"
    cat $config
fi
