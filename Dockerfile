FROM golang:1.14-buster as builder 

ENV GOPATH /usr/local/gopath 
ENV GO111MODULE off

WORKDIR $GOPATH/src/github.com/kubeflow/tf-operator

COPY . ./



RUN mkdir bin && \ 
	go build -o bin/tf-operator.v1 cmd/tf-operator.v1/main.go && \
	go build -o bin/backend        dashboard/backend/main.go

FROM debian:buster-20221004

RUN mkdir -pv /opt/kubeflow /opt/tensorflow_k8s/dashboard

COPY --from=builder /usr/local/gopath/src/github.com/kubeflow/tf-operator/bin/tf-operator.v1  /opt/kubeflow/tf-operator.v1

COPY --from=builder /usr/local/gopath/src/github.com/kubeflow/tf-operator/bin/backend  /opt/tensorflow_k8s/dashboard/backend

COPY dashboard/frontend/build  /opt/tensorflow_k8s/dashboard/frontend/build

RUN chmod +x /opt/kubeflow/tf-operator.v1 && \
	chmod +x /opt/tensorflow_k8s/dashboard/backend

CMD ["/opt/kubeflow/tf-operator.v1"]
