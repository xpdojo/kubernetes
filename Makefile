aws_cluster_name := capa-test

.PHONY: \
				clean-aws \
				init-aws \
				init-eks \
				cni-aws \

clean-aws:
	@./aws/scripts/clean.sh

init-aws:
	@./aws/scripts/init.sh
	
init-eks:
	@./aws/scripts/init-eks.sh

cni-aws:
	@./aws/scripts/cni.sh
