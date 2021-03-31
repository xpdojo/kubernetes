/*


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"

	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	examplev1alpha1 "markruler.com/api/v1alpha1"
)

// MachineReconciler reconciles a Machine object
type MachineReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=example.markruler.com,resources=machines,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=example.markruler.com,resources=machines/status,verbs=get;update;patch

func (r *MachineReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.Background()
	log := r.Log.WithValues("machine", req.NamespacedName)

	log.Info("Informer => Work Queue => Controller!")

	var machine examplev1alpha1.Machine

	if err := r.Get(ctx, req.NamespacedName, &machine); err != nil {
		log.Info("error GET Machine", "name", req.NamespacedName)
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	if machine.Spec.Role == "garbage" {
		if err := r.Delete(ctx, &machine); err != nil {
			log.Info("error DELETE Machine", "deleteName", req.NamespacedName)
			return ctrl.Result{}, client.IgnoreNotFound(err)
		}
		log.Info(">>> Deleted machine", "deleteName", req.NamespacedName)
		return ctrl.Result{}, nil
	}

	if !machine.Status.Ready {
		log.Info("Machine is not ready")
	}

	if machine.Spec.Role == "" {
		machine.Spec.Role = "garbage"
	}

	if machine.Spec.Role == "worker" {
		machine.Status.Ready = true
	} else {
		machine.Status.Ready = false
	}

	if err := r.Status().Update(ctx, &machine); err != nil {
		log.Info("error UPDATE status", "name", req.NamespacedName)
		return ctrl.Result{}, client.IgnoreNotFound(err)
	} else {
		log.Info("Update machine", "updatedName", req.NamespacedName)
	}

	return ctrl.Result{}, nil
}

func (r *MachineReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&examplev1alpha1.Machine{}).
		Complete(r)
}
