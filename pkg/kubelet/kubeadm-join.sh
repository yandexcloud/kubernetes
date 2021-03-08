set -e

RETRYIN=300

function join() {
    echo "[kubeadm-join] joining cluster ${@}"
    kubeadm join $@ --v 8
}

until join $@; do
    echo "[kubeadm-join] join failed, retrying in ${RETRYIN}"
    sleep $RETRYIN
done
