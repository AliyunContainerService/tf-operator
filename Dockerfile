FROM golang:1.18 as builder 

WORKDIR /workspace

COPY . .

RUN go build -o tf-operator.v1 cmd/tf-operator.v1/main.go && \
    go build -o backend dashboard/backend/main.go

FROM registry-cn-hangzhou.ack.aliyuncs.com/dev/debian:11-base

COPY --from=builder /workspace/tf-operator.v1 /opt/kubeflow/tf-operator.v1

COPY --from=builder /workspace/backend /opt/tensorflow_k8s/dashboard/backend

COPY dashboard/frontend/build /opt/tensorflow_k8s/dashboard/frontend/build

CMD ["/opt/kubeflow/tf-operator.v1"]
