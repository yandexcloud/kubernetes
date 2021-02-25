set -e

RETRYIN=10

function init() {
    echo "[kubeadm-init] initializing cluster"
    kubeadm init $@
    kubeadm init phase upload-certs $@ --upload-certs
}

until init $@; do
    echo "kubeadm-init] initialization failed, retrying in ${RETRYIN}"
    sleep $RETRYIN
done

for f in $(cat /run/config/init 2> /dev/null || true); do
    echo "[kubeadm-init] applying ${f}"
    kubectl apply -f $f
done
