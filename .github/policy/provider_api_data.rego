package main

import rego.v1

# Allow-list (default-deny) structural validation for provider_api/data.json
# against the `Provider` type: https://docs.stakingrewards.com/verified-provider-program/integrations-and-distribution/provider-api#provider-api. 
# Evaluated via `opa eval data.main.allow` as a
# required check before the automated data-update PR can be
# auto-approved/merged. On failure, dump `data.main` to see which specific
# sub-rule was false.

default allow := false

valid_node_types := {"hostingNode", "operatorNode", "posNode"}

allow if {
	valid_provider
	valid_supported_assets
}

valid_provider if {
	is_string(input.name)
	is_number(input.users)
	is_number(input.balanceUsd)
	is_array(input.supportedAssets)
}

valid_supported_assets if {
	every asset in input.supportedAssets {
		valid_asset(asset)
	}
}

valid_asset(asset) if {
	is_string(asset.name)
	is_string(asset.slug)
	is_array(asset.nodes)
	every node in asset.nodes {
		valid_node(node)
	}
}

valid_node(node) if {
	valid_node_types[node.nodeType]
	valid_node_address(node)
	is_number(node.users)
	is_number(node.balanceToken)
	valid_node_optional_number(node, "feeUsd")
	valid_node_optional_number(node, "balanceUsd")
	valid_node_optional_number(node, "fee")
	valid_node_optional_liquid_staking_provider(node)
}

# address is mandatory for posNode, optional (but must be a string when
# present) for the other node types.
valid_node_address(node) if {
	node.nodeType == "posNode"
	is_string(node.address)
}

valid_node_address(node) if {
	node.nodeType != "posNode"
	value := object.get(node, "address", null)
	value == null
}

valid_node_address(node) if {
	node.nodeType != "posNode"
	is_string(object.get(node, "address", null))
}

# generic optional-number check: absent, or present and numeric.
valid_node_optional_number(node, field) if {
	object.get(node, field, null) == null
}

valid_node_optional_number(node, field) if {
	is_number(object.get(node, field, null))
}

valid_node_optional_liquid_staking_provider(node) if {
	object.get(node, "liquidStakingProvider", null) == null
}

valid_node_optional_liquid_staking_provider(node) if {
	is_string(object.get(node, "liquidStakingProvider", null))
}
