#!/usr/bin/env bash
set -eo pipefail

cluster_name=$1
chart_version=$(jq -er .external_dns_chart_version $cluster_name.auto.tfvars.json)
cluster_domains=$(jq -er .cluster_domains $cluster_name.auto.tfvars.json)
AWS_ACCOUNT_ID=$(jq -er .aws_account_id $cluster_name.auto.tfvars.json)

echo "external-dns chart version $chart_version"

# add domains to external-dns domainFilter
declare -a domains=($(echo $cluster_domains | jq -r '.[]'))
cat <<EOF > cluster-domains-values.yaml
domainFilters:
EOF

for domain in "${domains[@]}";
do
  echo "  - $domain" >> cluster-domains-values.yaml
done

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

helm upgrade --install external-dns external-dns/external-dns \
             --version v$chart_version \
             --namespace istio-system \
             --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${AWS_ACCOUNT_ID}:role/PSKRoles/${cluster_name}-external-dns-sa \
             --set txtOwnerId=$cluster_name-twdps-labs \
             --values cluster-domains-values.yaml \
             --values external-dns/default-values.yaml
