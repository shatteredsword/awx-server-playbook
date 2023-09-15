#!/usr/bin/env bash
kubernetes_menu() {
	KUBERNETES=$(whiptail --title "AWX Installation" --radiolist \
	"Choose Your Kubernetes Distribution" 20 42 4 \
	"Minikube" "Kubernetes-maintained" ON \
	"K3s" "Lightweight Kubernetes" OFF \
	"MicroK8s" "Canonical-maintained" OFF \
	3>&1 1>&2 2>&3)
	EXITSTATUS=$?
	if [ $EXITSTATUS = 1 ]; then
	 	exit 1
	else
	 	firewall_menu
	fi
}
firewall_menu() {
	# "Firewalld" "NOT YET SUPPORTED" OFF \
	# "IPTables" "NOT YET SUPPORTED" OFF \
	# "NFTables" "NOT YET SUPPORTED" OFF \
	FIREWALL=$(whiptail --title "AWX Installation" --radiolist --cancel-button Back \
	"Choose Your Firewall Package" 20 42 4 \
	"UFW" "Canonical-maintained" ON \
	3>&1 1>&2 2>&3)
	EXITSTATUS=$?
	if [ $EXITSTATUS = 1 ]; then
		kubernetes_menu
	else
		hostname_menu
	fi
}
hostname_menu() {
	HOST=$(whiptail --title "AWX Installation" --inputbox --cancel-button Back \
	"Hostname for the AWX Instance?" 8 39 ansible.example.com \
	3>&1 1>&2 2>&3)
	EXITSTATUS=$?
	if [ $EXITSTATUS = 1 ]; then
		firewall_menu
	else
		user_menu
	fi
}

user_menu() {
	USERNAME=$(whiptail --title "AWX Installation" --inputbox --cancel-button Back \
	"Username to run AWX (must have sudo permissions and already exist on host)?" 8 39 ansible \
	3>&1 1>&2 2>&3)
	EXITSTATUS=$?
	if [ $EXITSTATUS = 1 ]; then
		hostname_menu
	else
		password_menu
	fi
}

password_menu() {
	PASSWORD=$(whiptail --title "AWX Installation" --passwordbox --cancel-button Back \
	"password for AWX Web Admin?" 8 39 \
	3>&1 1>&2 2>&3)
	EXITSTATUS=$?
	if [ $EXITSTATUS = 1 ]; then
		user_menu
	else
		dashboard_menu
	fi
}

dashboard_menu() {
	if (whiptail --title "AWX Installation" --yesno \
	"Enable Kubernetes Dashboard?" 8 39 \
	); then
		DASHBOARD="true"
		awx_cli_menu
	else
		DASHBOARD="false"
		awx_cli_menu
	fi
}

awx_cli_menu() {
	if (whiptail --title "AWX Installation" --yesno \
	"Install AWX CLI tools?" 8 39 \
	); then
		AWXCLI="true"
	else
		AWXCLI="false"
	fi
}

kubernetes_menu
ssh-copy-id "$USERNAME"@"$HOST"
START="$(date +%s)"
ansible-playbook awx_server_playbook.yml -i "$HOST," --ask-become-pass --extra-vars "awx_server_ssh_user=$USERNAME awx_server_host=$HOST awx_server_admin_password=$PASSWORD awx_server_k8s_method=$KUBERNETES awx_server_firewall_method=$FIREWALL awx_server_k8s_dashboard=$DASHBOARD awx_server_cli=$AWXCLI"
DURATION=$(( $(date +%s) - START ))
echo "playbook took ${DURATION} seconds"
