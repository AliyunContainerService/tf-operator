module github.com/kubeflow/tf-operator

go 1.18

require (
	github.com/emicklei/go-restful v2.16.0+incompatible
	github.com/go-openapi/spec v0.20.11
	github.com/golang/glog v1.1.0
	github.com/golang/protobuf v1.5.4
	github.com/kubernetes-sigs/kube-batch v0.4.2
	github.com/onrik/logrus v0.2.2
	github.com/prometheus/client_golang v0.9.3
	github.com/sirupsen/logrus v1.8.1
	github.com/stretchr/testify v1.9.0
	k8s.io/api v0.0.0-20180712090710-2d6f90ab1293
	k8s.io/apimachinery v0.0.0-20180621070125-103fd098999d
	k8s.io/client-go v0.0.0-20180806134042-1f13a808da65
	k8s.io/kube-openapi v0.0.0-20180509051136-39cb288412c4
	k8s.io/kubernetes v1.11.2
)

require (
	cloud.google.com/go/compute/metadata v0.4.0 // indirect
	github.com/beorn7/perks v1.0.0 // indirect
	github.com/coreos/etcd v3.3.27+incompatible // indirect
	github.com/coreos/go-semver v0.3.1 // indirect
	github.com/coreos/pkg v0.0.0-20240122114842-bbd7aa9bf6fb // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/docker/distribution v2.7.1+incompatible // indirect
	github.com/evanphx/json-patch v0.5.2 // indirect
	github.com/ghodss/yaml v1.0.0 // indirect
	github.com/go-openapi/jsonpointer v0.19.5 // indirect
	github.com/go-openapi/jsonreference v0.20.0 // indirect
	github.com/go-openapi/swag v0.19.15 // indirect
	github.com/gogo/protobuf v1.1.1 // indirect
	github.com/golang/groupcache v0.0.0-20241129210726-2c02b8208cf8 // indirect
	github.com/google/btree v1.1.3 // indirect
	github.com/google/go-cmp v0.7.0 // indirect
	github.com/google/gofuzz v1.2.0 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/googleapis/gnostic v0.0.0-00010101000000-000000000000 // indirect
	github.com/gregjones/httpcache v0.0.0-20190611155906-901d90724c79 // indirect
	github.com/hashicorp/golang-lru v1.0.2 // indirect
	github.com/imdario/mergo v0.0.0-00010101000000-000000000000 // indirect
	github.com/josharian/intern v1.0.0 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/mailru/easyjson v0.7.7 // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.1 // indirect
	github.com/modern-go/concurrent v0.0.0-20180228061459-e0a39a4cb421 // indirect
	github.com/modern-go/reflect2 v1.0.2 // indirect
	github.com/onsi/ginkgo v1.16.5 // indirect
	github.com/onsi/gomega v1.15.0 // indirect
	github.com/opencontainers/go-digest v1.0.0 // indirect
	github.com/pborman/uuid v1.2.1 // indirect
	github.com/peterbourgon/diskv v2.0.1+incompatible // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/prometheus/client_model v0.0.0-20190812154241-14fe0d1b01d4 // indirect
	github.com/prometheus/common v0.4.0 // indirect
	github.com/prometheus/procfs v0.0.0-20190507164030-5867b95ac084 // indirect
	github.com/spf13/afero v1.8.0 // indirect
	github.com/spf13/pflag v1.0.6 // indirect
	go.uber.org/zap v1.27.0 // indirect
	golang.org/x/crypto v0.15.0 // indirect
	golang.org/x/net v0.18.0 // indirect
	golang.org/x/oauth2 v0.20.0 // indirect
	golang.org/x/sys v0.31.0 // indirect
	golang.org/x/term v0.30.0 // indirect
	golang.org/x/text v0.23.0 // indirect
	golang.org/x/time v0.11.0 // indirect
	google.golang.org/protobuf v1.33.0 // indirect
	gopkg.in/inf.v0 v0.9.1 // indirect
	gopkg.in/square/go-jose.v2 v2.6.0 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
	k8s.io/apiextensions-apiserver v0.0.0-00010101000000-000000000000 // indirect
	k8s.io/apiserver v0.0.0-20180808060109-1844acd6a035 // indirect
)

replace (
	cloud.google.com/go => cloud.google.com/go v0.36.0
	github.com/googleapis/gnostic => github.com/google/gnostic v0.2.0
	github.com/imdario/mergo => dario.cat/mergo v0.3.7

	k8s.io/api => k8s.io/api v0.0.0-20180712090710-2d6f90ab1293
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.0.0-20180808065829-408db4a50408
	k8s.io/apimachinery => k8s.io/apimachinery v0.0.0-20180621070125-103fd098999d
	k8s.io/apiserver => k8s.io/apiserver v0.0.0-20180808060109-1844acd6a035
	k8s.io/client-go => k8s.io/client-go v0.0.0-20180806134042-1f13a808da65
	k8s.io/kube-openapi => k8s.io/kube-openapi v0.0.0-20180509051136-39cb288412c4
	k8s.io/kubernetes => k8s.io/kubernetes v1.11.2
)

exclude k8s.io/apiserver/pkg/server v0.0.0-20180808060109-1844acd6a035
