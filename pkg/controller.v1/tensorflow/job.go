package tensorflow

import (
	"fmt"
	"reflect"
	"time"

	log "github.com/sirupsen/logrus"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	metav1unstructured "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/kubernetes/scheme"

	common "github.com/kubeflow/tf-operator/pkg/apis/common/v1"
	tfv1 "github.com/kubeflow/tf-operator/pkg/apis/tensorflow/v1"
	tflogger "github.com/kubeflow/tf-operator/pkg/logger"
	"github.com/kubeflow/tf-operator/pkg/util"
	"github.com/kubeflow/tf-operator/pkg/util/k8sutil"
)

const (
	failedMarshalTFJobReason = "InvalidTFJobSpec"
)

// When a pod is added, set the defaults and enqueue the current tfjob.
func (tc *TFController) addTFJob(obj interface{}) {
	// Convert from unstructured object.
	tfJob, err := tfJobFromUnstructured(obj)
	if err != nil {
		un, ok := obj.(*metav1unstructured.Unstructured)
		logger := &log.Entry{}
		if ok {
			logger = tflogger.LoggerForUnstructured(un, tfv1.Kind)
		}
		logger.Errorf("Failed to convert the TFJob: %v", err)
		// Log the failure to conditions.
		if err == errFailedMarshal {
			errMsg := fmt.Sprintf("Failed to marshal the object to TFJob; the spec is invalid: %v", err)
			logger.Warn(errMsg)
			// TODO(jlewi): v1 doesn't appear to define an error type.
			tc.Recorder.Event(un, corev1.EventTypeWarning, failedMarshalTFJobReason, errMsg)

			status := common.JobStatus{
				Conditions: []common.JobCondition{
					common.JobCondition{
						Type:               common.JobFailed,
						Status:             corev1.ConditionTrue,
						LastUpdateTime:     metav1.Now(),
						LastTransitionTime: metav1.Now(),
						Reason:             failedMarshalTFJobReason,
						Message:            errMsg,
					},
				},
			}

			statusMap, err := runtime.DefaultUnstructuredConverter.ToUnstructured(&status)

			if err != nil {
				logger.Errorf("Could not covert the TFJobStatus to unstructured; %v", err)
				return
			}

			client, err := k8sutil.NewCRDRestClient(&tfv1.SchemeGroupVersion)

			if err == nil {
				if err1 := metav1unstructured.SetNestedField(un.Object, statusMap, "status"); err1 != nil {
					logger.Errorf("Could not set nested field: %v", err1)
				}
				logger.Infof("Updating the job to: %+v", un.Object)
				err = client.UpdateStatus(un, tfv1.Plural)
				if err != nil {
					logger.Errorf("Could not update the TFJob: %v", err)
				}
			} else {
				logger.Errorf("Could not create a REST client to update the TFJob")
			}
		}
		return
	}

	// Set default for the new tfjob.
	scheme.Scheme.Default(tfJob)

	msg := fmt.Sprintf("TFJob %s is created.", tfJob.Name)
	logger := tflogger.LoggerForJob(tfJob)
	logger.Info(msg)

	// Add a created condition.
	err = updateTFJobConditions(tfJob, common.JobCreated, tfJobCreatedReason, msg)
	if err != nil {
		logger.Errorf("Append tfJob condition error: %v", err)
		return
	}

	// Convert from tfjob object
	err = unstructuredFromTFJob(obj, tfJob)
	if err != nil {
		logger.Errorf("Failed to convert the obj: %v", err)
		return
	}
	tc.enqueueTFJob(obj)
	CreatedTFJobsCounterInc(tfJob.Namespace)

	// add a new rsync for StartingDeadlineSeconds
	key, err := KeyFunc(tfJob)
	if err != nil {
		return
	}
	if tfJob.Spec.StartingDeadlineSeconds != nil {
		logger.Infof("Job with StartingDeadlineSeconds will sync after %d seconds", *tfJob.Spec.StartingDeadlineSeconds)
		tc.WorkQueue.AddAfter(key, time.Duration(*tfJob.Spec.StartingDeadlineSeconds)*time.Second)
	}
}

// When a pod is updated, enqueue the current tfjob.
func (tc *TFController) updateTFJob(old, cur interface{}) {
	oldTFJob, err := tfJobFromUnstructured(old)
	if err != nil {
		return
	}
	curTFJob, err := tfJobFromUnstructured(cur)
	if err != nil {
		return
	}

	// never return error
	key, err := KeyFunc(curTFJob)
	if err != nil {
		return
	}

	cleanPodPolicyNone := oldTFJob.Spec.CleanPodPolicy != nil && *oldTFJob.Spec.CleanPodPolicy == common.CleanPodPolicyNone
	if !(util.CheckJobCompletedV1(oldTFJob.Status.Conditions) && oldTFJob.DeletionTimestamp == nil &&
		(cleanPodPolicyNone || oldTFJob.Annotations[TFCleanPodStatusLabel] == TFCleanStatusDone)) {
		log.Infof("Updating tfjob: %s", oldTFJob.Name)
		tc.enqueueTFJob(cur)
	}

	// check if need to add a new rsync for ActiveDeadlineSeconds
	if curTFJob.Status.StartTime != nil {
		curTFJobADS := curTFJob.Spec.ActiveDeadlineSeconds
		if curTFJobADS != nil {
			oldTFJobADS := oldTFJob.Spec.ActiveDeadlineSeconds
			if oldTFJobADS == nil || *oldTFJobADS != *curTFJobADS {
				now := metav1.Now()
				start := curTFJob.Status.StartTime.Time
				passed := now.Time.Sub(start)
				total := time.Duration(*curTFJobADS) * time.Second
				// AddAfter will handle total < passed
				tc.WorkQueue.AddAfter(key, total-passed)
				log.Infof("job ActiveDeadlineSeconds updated, will rsync after %d seconds", total-passed)
			}
		}
	}

	// check if need to add a new rsync for StartingDeadlineSeconds
	curTFJobSDS := curTFJob.Spec.StartingDeadlineSeconds
	if curTFJobSDS != nil {
		oldTFJobSDS := oldTFJob.Spec.StartingDeadlineSeconds
		if oldTFJobSDS == nil || *oldTFJobSDS != *curTFJobSDS {
			now := metav1.Now()
			start := curTFJob.ObjectMeta.CreationTimestamp.Time
			passed := now.Time.Sub(start)
			total := time.Duration(*curTFJobSDS) * time.Second
			// AddAfter will handle total < passed
			tc.WorkQueue.AddAfter(key, total-passed)
			log.Infof("job StartingDeadlineSeconds updated, will rsync after %d seconds", total-passed)
		}
	}
}

func (tc *TFController) deletePodsAndServices(tfJob *tfv1.TFJob, pods []*corev1.Pod) error {
	if len(pods) == 0 {
		return nil
	}

	logger := tflogger.LoggerForJob(tfJob)

	cleanPodPolicy := getCleanPodPolicy(tfJob)
	switch cleanPodPolicy {
	case common.CleanPodPolicyUndefined, common.CleanPodPolicyNone:
		logger.Infof("Do nothing when the clean pod policy is %s.", cleanPodPolicy)
		return nil
	case common.CleanPodPolicyRunning:
		logger.Infof("Deleting running pods and associated services.")
		if err := tc.deleteRunningPodsAndServices(tfJob, pods); err != nil {
			return err
		}
	case common.CleanPodPolicyAll:
		logger.Infof("Deleting all pods and associated services.")
		if err := tc.deleteAllPodsAndServices(tfJob, pods); err != nil {
			return err
		}
	default:
		return fmt.Errorf("the clean pod policy %s is not supported", cleanPodPolicy)
	}

	tfjobToUpdate := tfJob.DeepCopy()

	if tfjobToUpdate.Annotations == nil {
		tfjobToUpdate.Annotations = map[string]string{}
	}

	tfjobToUpdate.Annotations[TFCleanPodStatusLabel] = TFCleanStatusDone
	if !reflect.DeepEqual(tfJob, tfjobToUpdate) {
		_, err := tc.tfJobClientSet.KubeflowV1().TFJobs(tfjobToUpdate.Namespace).Update(tfjobToUpdate)
		if err != nil {
			return err
		}
	}

	return nil
}

func (tc *TFController) deleteRunningPodsAndServices(tfJob *tfv1.TFJob, pods []*corev1.Pod) error {
	for _, pod := range pods {
		if pod.Status.Phase != corev1.PodPending && pod.Status.Phase != corev1.PodRunning {
			continue
		}

		if err := tc.PodControl.DeletePod(pod.Namespace, pod.Name, tfJob); err != nil {
			return err
		}

		// Pod and service have the same name, thus the service could be deleted using pod's name.
		if err := tc.ServiceControl.DeleteService(pod.Namespace, pod.Name, tfJob); err != nil {
			return err
		}
	}
	return nil
}

func (tc *TFController) deleteAllPodsAndServices(tfJob *tfv1.TFJob, pods []*corev1.Pod) error {
	for _, pod := range pods {
		if err := tc.PodControl.DeletePod(pod.Namespace, pod.Name, tfJob); err != nil {
			return err
		}

		// Pod and service have the same name, thus the service could be deleted using pod's name.
		if err := tc.ServiceControl.DeleteService(pod.Namespace, pod.Name, tfJob); err != nil {
			return err
		}
	}
	return nil
}

func (tc *TFController) cleanupTFJob(tfJob *tfv1.TFJob) error {
	currentTime := time.Now()
	ttl := tfJob.Spec.TTLSecondsAfterFinished
	if ttl == nil {
		// do nothing if the cleanup delay is not set
		return nil
	}
	duration := time.Second * time.Duration(*ttl)
	if tfJob.Status.CompletionTime == nil {
		return fmt.Errorf("job completion time is nil, cannot cleanup")
	}
	finishTime := tfJob.Status.CompletionTime
	expireTime := finishTime.Add(duration)
	if currentTime.After(expireTime) {
		err := tc.deleteTFJobHandler(tfJob)
		if err != nil {
			tflogger.LoggerForJob(tfJob).Warnf("Cleanup TFJob error: %v.", err)
			return err
		}
		return nil
	} else {
		remaining := expireTime.Sub(currentTime)
		key, err := KeyFunc(tfJob)
		if err != nil {
			tflogger.LoggerForJob(tfJob).Warnf("Couldn't get key for tfjob object: %v", err)
			return err
		}
		tc.WorkQueue.AddAfter(key, remaining)
		return nil
	}
}

// deleteTFJob deletes the given TFJob.
func (tc *TFController) deleteTFJob(tfJob *tfv1.TFJob) error {
	return tc.tfJobClientSet.KubeflowV1().TFJobs(tfJob.Namespace).Delete(tfJob.Name, &metav1.DeleteOptions{})
}

func getCleanPodPolicy(tfJob *tfv1.TFJob) common.CleanPodPolicy {
	if tfJob.Spec.CleanPodPolicy != nil {
		return *tfJob.Spec.CleanPodPolicy
	}
	return common.CleanPodPolicyUndefined
}

func getTotalReplicas(tfjob *tfv1.TFJob) int32 {
	tfjobReplicas := int32(0)
	for _, r := range tfjob.Spec.TFReplicaSpecs {
		tfjobReplicas += *r.Replicas
	}
	return tfjobReplicas
}

func getTotalFailedReplicas(tfjob *tfv1.TFJob) int32 {
	totalFailedReplicas := int32(0)
	for rtype := range tfjob.Status.ReplicaStatuses {
		totalFailedReplicas += tfjob.Status.ReplicaStatuses[rtype].Failed
	}
	return totalFailedReplicas
}
