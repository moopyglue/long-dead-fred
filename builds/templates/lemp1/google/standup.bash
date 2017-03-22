#!/bin/bash 

export PROVIDER=google

(

if [[ $PROJECT = "" || $ZONE = "" || $TEMPLATE = "" || $INSTANCE = "" || $POOL_TOOL_ROOT = "" ]] ; then
	echo "missing environment variables, exiting" 1>&2
	exit 1
fi

echo cd $POOL_TOOL_ROOT/templates/$TEMPLATE/$PROVIDER
cd $POOL_TOOL_ROOT/templates/$TEMPLATE/$PROVIDER
if [[ $( pwd ) != $POOL_TOOL_ROOT/templates/$TEMPLATE/$PROVIDER ]] ; then
	echo "unable to change to template/provider directory" 1>&2
	exit 1
fi

# change any configurable items in  build
[[ $PREMPTABLE = true ]] && EXTRA_FLAGS="$EXTRA_FLAGS --preemptible"
DISK_TYPE="pd-standard"
[[ $USE_SSD = true ]] && DISK_TYPE="pd-ssd"
echo "DiskType: $DISK_TYPE"


echo "-> standing up [${INSTANCE}] template=$TEMPLATE project=${PROJECT} zone=$ZONE extraflags='$EXTRA_FLAGS'"
gcloud compute \
	--project "${PROJECT}" \
	instances create "${INSTANCE}" \
	--zone "${ZONE}" \
	--machine-type "g1-small" \
	--subnet "default" \
	--no-restart-on-failure \
	--maintenance-policy "TERMINATE" \
	$EXTRA_FLAGS \
	--tags "qm-$TEMPLATE" \
	--image "debian-8-jessie-v20170124" \
	--image-project "debian-cloud" \
	--boot-disk-size "10" \
	--boot-disk-type "${DISK_TYPE}" \
	--boot-disk-device-name "${INSTANCE}_$(date +"%y%m%d_%H%M%S")" \
	|| exit $?

httprule="$(gcloud compute --project ${PROJECT} firewall-rules list | awk '$NF == "http-server" { print "exists" }')"
[[ $httprule == "exists" ]] || \
		gcloud compute --project "${PROJECT}" firewall-rules create "default-allow-http"  \
		--allow tcp:80  --network "default" --source-ranges "0.0.0.0/0" --target-tags "http-server" || exit $?

httpsrule="$(gcloud compute --project ${PROJECT} firewall-rules list | awk '$NF == "https-server" { print "exists" }')"
[[ $httpsrule == "exists" ]] || \
		gcloud compute --project "${PROJECT}" firewall-rules create "default-allow-https"  \
		--allow tcp:443  --network "default" --source-ranges "0.0.0.0/0" --target-tags "https-server" || exit $?

echo "-> creating remote build directory"
gcloud compute --project ${PROJECT} ssh --zone $ZONE build@$INSTANCE --command="mkdir /tmp/build " || exit $?

echo "-> copying files to new instance"
gcloud compute --project ${PROJECT} copy-files ./* $POOL_TOOL_ROOT/share/* build@$INSTANCE:/tmp/build --zone $ZONE || exit $?

echo "-> Build Instance Initiated"
gcloud compute --project ${PROJECT} ssh --zone $ZONE build@$INSTANCE --command="/tmp/build/run-multi /tmp/build/instance-build.bash " || exit $?

echo
echo "-> Adding http/https tags to open firewall"
gcloud compute --project ${PROJECT} instances add-tags --zone $ZONE $INSTANCE --tags "http-server","https-server" || exit $?

echo
echo "INSTANCE RUNNING"
gcloud compute --project ${PROJECT} instances list | awk '$1 == "'$INSTANCE'" { print }'

)


