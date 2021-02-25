set -e

RETRYIN=10

function join() {
    echo "[kubeadm-join] joining cluster"
    kubeadm join $@
}

until join $@; do
    echo "[kubeadm-join] join failed, retrying in ${RETRYIN}"
    sleep $RETRYIN
done
