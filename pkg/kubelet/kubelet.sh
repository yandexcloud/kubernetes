#!/bin/sh

cri_sock=/run/containerd/containerd.sock
args_file=/run/config/kubelet/args
token_cmd='ctr -n services.linuxkit t exec --exec-id e1 kubelet kubeadm token create --print-join-command'

function set_bootstrap_token() {
    echo "${0} [info] getting bootstrap token..."
    until joincmd=$(ssh -o StrictHostKeyChecking=no $1 ${token_cmd}); do
        sleep 10
    done
    echo "${0} [info] bootstrap token received"

    token=$(echo $joincmd | awk '{print $5}')
    ca_cert_hash=$(echo $joincmd | awk '{print $7}')

    sed -i s/\$\{token\}/${token}/g $2
    sed -i s/\$\{ca_cert_hash\}/${ca_cert_hash}/g $2
}

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
        set_bootstrap_token root@$m0 /run/config/kubeadm/join.yaml
        kubeadm-join.sh $m0:6443 --config /run/config/kubeadm/join.yaml &
        await="/etc/kubernetes/bootstrap-kubelet.conf"
    fi

    echo "${0} [info]: waiting for ${await}"
    until [[ -f "${await}" ]]; do
        sleep 5
    done

    echo "${0} [info]: ${await} has arrived"
}

export $(cat /run/config/kubernetes)

if [[ -f "/etc/kubernetes/kubelet.conf" ]]; then
    echo "${0} [info]: kubelet already configured"
else
    echo "${0} [info]: starting bootstrap process"
    bootstrap
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
