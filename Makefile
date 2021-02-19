aws_cluster_name := capa-test

.PHONY: \
				aws-init \
				aws-status \
				eks-init \
				eks-status \
				clean-aws \
				clean-eks \
				aws-cni \

clean-aws:
	kubectl delete cluster $(aws_cluster_name)
	clusterctl delete --infrastructure aws
	kind delete cluster --name $(aws_cluster_name)

clean-eks:
	kubectl delete cluster $(aws_cluster_name)
	clusterctl delete --infrastructure aws --control-plane aws-eks --bootstrap aws-eks
	kind delete cluster --name $(aws_cluster_name)

aws-init:
	@./aws/scripts/capi-aws-init.sh
	
aws-status:
	clusterctl describe cluster $(aws_cluster_name)

eks-init:
	@./aws/scripts/eks-init.sh

eks-status:
	clusterctl describe cluster $(aws_cluster_name)

aws-cni:
	@./aws/scripts/capi-aws-cni.sh
