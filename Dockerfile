FROM golang:1.14-buster as builder 

ENV GOPATH /usr/local/gopath 

ENV GO111MODULE off

WORKDIR $GOPATH/src/github.com/kubeflow/tf-operator

COPY . ./

RUN mkdir -p bin && \ 
    go build -o bin/tf-operator.v1 cmd/tf-operator.v1/main.go && \
    go build -o bin/backend dashboard/backend/main.go

FROM registry-cn-hangzhou.ack.aliyuncs.com/dev/debian:11-base

COPY --from=builder /usr/local/gopath/src/github.com/kubeflow/tf-operator/bin/tf-operator.v1 /opt/kubeflow/tf-operator.v1

COPY --from=builder /usr/local/gopath/src/github.com/kubeflow/tf-operator/bin/backend /opt/tensorflow_k8s/dashboard/backend

COPY dashboard/frontend/build /opt/tensorflow_k8s/dashboard/frontend/build

CMD ["/opt/kubeflow/tf-operator.v1"]
