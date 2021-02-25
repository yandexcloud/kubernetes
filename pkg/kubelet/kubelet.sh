#!/bin/sh

cri_sock=/run/containerd/containerd.sock
args_file=/run/config/kubelet/args

function bootstrap() {
    me=$(hostname)
    echo "${0} [info] me=${me}"
    all=$(iglist -folder ${FOLDER} -group ${GROUP} 2> /var/log/iglist.log)
    echo "${0} [info] all=${all}"
    m0=$(echo $all | sed 's/ /\n/g' | head -n 1)
    echo "${0} [info] m0=${m0}"

    if [[ -z $all ]]; then
        echo "${0} [error] variable 'all' is not set"
        return 1
    fi
    
    if [[  -z $m0 ]]; then
        echo "${0} [error] variable 'm0' is not set"
        return 1
    fi

    if [[ $me = $m0 ]]; then
        kubeadm-init.sh --config /run/config/kubeadm/init.yaml &
        await="/etc/kubernetes/kubelet.conf"
    else
        kubeadm-join.sh $m0:6443 --config /run/config/kubeadm/join.yaml &
        await="/etc/kubernetes/bootstrap-kubelet.conf"
    fi

    echo "${0} [info]: waiting for ${await}"
    until [[ -f "${await}" ]]; do
        sleep 5
    done

    if [[ $n -eq 0 ]]; then
        return 1
    fi

    echo "${0} [info]: ${await} has arrived" 2>&1

    for l in $(cat /run/config/labels 2> /dev/null || true); do
        kubectl label nodes $me $l
    done
}

export $(cat /run/config/kubernetes)

if [[ -f "/etc/kubernetes/kubelet.conf" ]]; then
    echo "${0} [info]: kubelet already configured"
else
    until bootstrap ; do
        echo "${0} [error]: bootstrap failed, retrying in 5sec"
        sleep 5
    done
fi


if [[ -f ${args_file} ]]; then
    kubelet_args=$(cat ${args_file})
fi

echo "${0} [info]: starting kubelet with additional args: ${kubelet_args}"
exec kubelet \
    --config=/run/config/kubelet/kubelet.yaml \
    --kubeconfig=/etc/kubernetes/kubelet.conf \
    --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
    --network-plugin=cni \
    --cni-conf-dir=/etc/cni/net.d \
    --cni-bin-dir=/var/lib/cni/bin \
    --container-runtime=remote \
    --container-runtime-endpoint=unix:///${cri_sock} \
    ${kubelet_args}
