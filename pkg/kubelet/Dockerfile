FROM alpine:3.13 AS build

ARG KUBERNETES_VERSION=
ARG CNI_VERSION=
ARG CRITOOLS_VERSION=

ARG KUBERNETES_URL=https://github.com/kubernetes/kubernetes
ARG CRITOOLS_URL=https://github.com/kubernetes-incubator/cri-tools
ARG IGLIST_URL=https://github.com/yandexcloud/iglist

ENV GOPATH=/go PATH=$PATH:/go/bin

RUN test -n ${KUBERNETES_VERSION}
RUN test -n ${CRITOOLS_URL}

RUN apk add -U --no-cache \
  bash \
  coreutils \
  curl \
  findutils \
  git \
  go \
  grep \
  libc-dev \
  linux-headers \
  make \
  rsync

RUN mkdir /out

### Kubernetes
RUN mkdir -p $GOPATH/src/github.com/kubernetes && \
    cd $GOPATH/src/github.com/kubernetes && \
    git clone ${KUBERNETES_URL} kubernetes
WORKDIR $GOPATH/src/github.com/kubernetes/kubernetes
RUN git checkout -q ${KUBERNETES_VERSION}
RUN make WHAT="cmd/kubelet cmd/kubectl cmd/kubeadm"

RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubelet /out/kubelet
RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubeadm /out/kubeadm
RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubectl /out/kubectl

### Critools
RUN mkdir -p $GOPATH/github.com/kubernetes-incubator && \
    cd $GOPATH/github.com/kubernetes-incubator && \
    git clone ${CRITOOLS_URL} cri-tools
WORKDIR $GOPATH/github.com/kubernetes-incubator/cri-tools
RUN git checkout -q ${CRITOOLS_VERSION}
RUN make binaries

RUN cp _output/crictl /out/crictl
RUN cp _output/critest /out/critest

### Yandex Cloud tools
RUN mkdir -p $GOPATH/github.com/yandexcloud && \
    cd $GOPATH/github.com/yandexcloud && \
    git clone ${IGLIST_URL}
WORKDIR $GOPATH/github.com/yandexcloud/iglist
RUN go build -ldflags="-s -w" -o /out/iglist

RUN apk add upx
RUN upx /out/kubectl
RUN upx /out/kubeadm
RUN upx /out/kubelet
RUN upx /out/critest
RUN upx /out/crictl
RUN upx /out/iglist

FROM alpine:3.13 AS image
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    busybox \
    ca-certificates \
    coreutils \
    curl \
    ebtables \
    ethtool \
    findutils \
    iproute2 \
    iptables \
    musl \
    openssl \
    socat \
    util-linux \
    nfs-utils \
    conntrack-tools
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache
COPY --from=build /out/kubectl /out/usr/bin/kubectl
COPY --from=build /out/kubeadm /out/usr/bin/kubeadm
COPY --from=build /out/kubelet /out/usr/bin/kubelet
COPY --from=build /out/critest /out/usr/bin/critest
COPY --from=build /out/crictl /out/usr/bin/crictl
COPY --from=build /out/iglist /out/usr/bin/iglist

COPY kubelet.sh /out/usr/bin/kubelet.sh
COPY kubeadm-init.sh /out/usr/bin/kubeadm-init.sh
COPY kubeadm-join.sh /out/usr/bin/kubeadm-join.sh

FROM scratch
COPY --from=image /out /
WORKDIR /
ENV KUBECONFIG "/etc/kubernetes/admin.conf"
ENV CONTAINER_RUNTIME_ENDPOINT "unix:///run/containerd/containerd.sock"
ENTRYPOINT ["/usr/bin/kubelet.sh"]
