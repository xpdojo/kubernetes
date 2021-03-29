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

	gcv1alpha1 "markruler.com/api/v1alpha1"
)

// RulerReconciler reconciles a Ruler object
type RulerReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=gc.markruler.com,resources=rulers,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=gc.markruler.com,resources=rulers/status,verbs=get;update;patch

func (r *RulerReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.Background()
	log := r.Log.WithValues("ruler", req.NamespacedName)

	log.Info("Informer => Work Queue => Controller!")

	var ruler gcv1alpha1.Ruler

	if err := r.Get(ctx, req.NamespacedName, &ruler); err != nil {
		log.Info("error getting object", "name", req.NamespacedName)
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	if ruler.Status.Mark == true {
		if err := r.Delete(ctx, &ruler); err != nil {
			log.Info("error delete object", "deleteName", req.NamespacedName)
			return ctrl.Result{}, client.IgnoreNotFound(err)
		}
		log.Info(">>> deleted ruler", "deleteName", req.NamespacedName)
		return ctrl.Result{}, nil
	}

	if ruler.Spec.Type == "" {
		ruler.Spec.Type = "garbage"
	}

	if ruler.Spec.Type == "garbage" {
		ruler.Status.Mark = true
	}

	if err := r.Status().Update(ctx, &ruler); err != nil {
		log.Info("error updating status", "name", req.NamespacedName)
		return ctrl.Result{}, client.IgnoreNotFound(err)
	} else {
		log.Info("Update Ruler", "updatedName", req.NamespacedName)
	}

	return ctrl.Result{}, nil
}

func (r *RulerReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&gcv1alpha1.Ruler{}).
		Complete(r)
}
