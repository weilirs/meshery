package relationship_evaluation_policy

import rego.v1

# Evaluates the relationships which needs to be added based on the current state of design file.

evaluate_relationships_deleted(
	design_file,
	identified_relationships,
) := result if {
	deleted_relationships := [rel |
		some existing_rel in design_file.relationships

		# if the existing rel is not present in the identified_relationships,
		# it indicates it must be deleted.
		not temp_rule(existing_rel, identified_relationships)
		relationship := json.patch(existing_rel, [{
			"op": "replace",
			"path": "/status",
			"value": "deleted",
		}])
		rel := relationship
	]
}

temp_rule(existing_rel, identified_rels) if {
	some rel in identified_rels
	is_of_same_kind(existing_rel, rel)
	does_belongs_to_same_model(existing_rel, rel)
	is_same_selector(existing_rel, rel)
	relationship := existing_rel
}

# Evaluates the relationships which needs to be added based on the current state of design file.

evaluate_relationships_added(
	design_file,
	identified_relationships,
) := [relationship |
	some rel in identified_relationships

	not does_relationship_exist_in_design(design_file, rel)
	relationship := rel
]

does_relationship_exist_in_design(design_file, identified_rel) if {
	some existing_rel in design_file

	is_of_same_kind(existing_rel, identified_rel)
	does_belongs_to_same_model(existing_rel, identified_rel)
	is_same_selector(existing_rel, identified_rel)
}

is_of_same_kind(existing_rel, new_rel) if {
	new_rel.kind == existing_rel.kind
	new_rel.type == existing_rel.type
	new_rel.subType == existing_rel.subTyp
}

default does_belongs_to_same_model := true

# consider for wildcard in name and version?
does_belongs_to_same_model(existing_rel, new_rel) if {
	new_rel.model.name == existing_rel.model.name
	new_rel.model.model.version == existing_rel.model.model.version
}

is_same_selector(existing_rel, new_rel) if {
	some ex_selector in existing_rel.selectors
	some selector in new_rel.selectors

	# the rels that are inside design file, have only one element in the "from" and "to".
	ex_from_selector := ex_selector.allow.from[0]
	from_selector := selector.allow.from[0]

	ex_to_selector := ex_selector.allow.to[0]
	to_selector := selector.allow.to[0]

	# is relationship between same components or different
	ex_from_selector.id == from_selector.id
	ex_to_selector.id == to_selector.id

	# check if the relationship includes binding component.
	# If present, verify the binding component for the existing and the identified relationship are same or different.
	has_key(ex_from_selector, "match")
	has_key(from_selector, "match")

	is_same_binding_declaration(ex_from_selector, ex_to_selector, from_selector, to_selector)
}

is_same_binding_declaration(ex_from_selector, ex_to_selector, from_selector, to_selector) if {
	existing_binding := {
		ex_from_selector.match.from[0].id,
		ex_from_selector.match.to[0].id,
		ex_to_selector.match.to[0].id,
	}

	identified_binding := {
		from_selector.match.from[0].id,
		from_selector.match.to[0].id,
		to_selector.match.to[0].id,
	}
}