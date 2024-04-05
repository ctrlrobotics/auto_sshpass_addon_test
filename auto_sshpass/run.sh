#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json

USERNAME=$(jq --raw-output '.username' $CONFIG_PATH)
PASSWORD=$(jq --raw-output '.password' $CONFIG_PATH)
HOSTNAME=$(jq --raw-output '.hostname' $CONFIG_PATH)
LOCAL_HOST=$(jq --raw-output '.local_host' $CONFIG_PATH)
LOCAL_PORT=$(jq --raw-output '.local_port' $CONFIG_PATH)
REMOTE_HOST=$(jq --raw-output '.remote_host' $CONFIG_PATH)
REMOTE_PORT=$(jq --raw-output '.remote_port' $CONFIG_PATH)
SLACK_WEBHOOK=$(jq --raw-output '.slack_webhook' $CONFIG_PATH)

send_slack_message () {

	if [ -z "$SLACK_WEBHOOK" ]; then
		bashio::log.info "No slack webhook provided, skipping"
		return
	fi

	curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$1\"}" $SLACK_WEBHOOK
}

while :; do
  	bashio::log.info "Attempting to connect to ${HOSTNAME} as ${USERNAME}..."
  	sshpass -v \
    	-p "${PASSWORD}" \
	    ssh \
	      -o "ServerAliveInterval 60" \
	      -o "ServerAliveCountMax 2" \
	      -o "ConnectTimeout 15" \
	      -o "ExitOnForwardFailure yes" \
	      -o "StrictHostKeyChecking no" \
	      -4 -R "${REMOTE_HOST}:${REMOTE_PORT}:${LOCAL_HOST}:${LOCAL_PORT}" -N "${USERNAME}@${HOSTNAME}"

	exit_status=$?

	if [ $exit_status -eq 255 ]; then
		error_message="SSH tunnel connection disconnected, server: ${USERNAME}@${HOSTNAME} ${REMOTE_HOST}:${REMOTE_PORT}, wait 15s before re-trying"
	else
		error_message="SSH tunnel connection disconnected with status $exit_status, server: ${USERNAME}@${HOSTNAME} ${REMOTE_HOST}:${REMOTE_PORT}, wait 15s before re-trying"
	fi

	bashio::log.error "$error_message"
	send_slack_message "$error_message"

    sleep 2
done