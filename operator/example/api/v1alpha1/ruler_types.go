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

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// RulerSpec defines the desired state of Ruler
type RulerSpec struct {
	Type string `json:"type,omitempty"`
}

// RulerStatus defines the observed state of Ruler
type RulerStatus struct {
	Mark bool `json:"mark"`
}

// +kubebuilder:object:root=true
// +kubebuilder:printcolumn:name="type",type=string,JSONPath=`.spec.type`
// +kubebuilder:printcolumn:name="mark",type=boolean,JSONPath=`.status.mark`
// +kubebuilder:subresource:status

// Ruler is the Schema for the rulers API
type Ruler struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   RulerSpec   `json:"spec,omitempty"`
	Status RulerStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// RulerList contains a list of Ruler
type RulerList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Ruler `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Ruler{}, &RulerList{})
}
