# Sourced by the other .devcontainer/bin/* scripts. Provides runtime
# detection (docker vs podman) and compose project-name derivation.

detect_runtime() {
	if [ -n "${CONTAINER_CLI:-}" ] && command -v "$CONTAINER_CLI" >/dev/null 2>&1; then
		echo "$CONTAINER_CLI"
	elif command -v docker >/dev/null 2>&1; then
		echo docker
	elif command -v podman >/dev/null 2>&1; then
		echo podman
	else
		echo ".devcontainer/bin: neither docker nor podman found on PATH" >&2
		exit 1
	fi
}

# docker keeps hyphens in the sanitized project name; podman-compose strips
# them. Read the authoritative value back from a running container's label;
# fall back to compose.yaml's name: field if nothing is up yet.
compose_project() {
	local runtime=$1 devcontainer_dir cid
	devcontainer_dir="$(readlink -f .)/.devcontainer"

	cid=$("$runtime" ps -q \
		--filter "label=com.docker.compose.service=app" \
		--filter "label=com.docker.compose.project.working_dir=$devcontainer_dir" \
		| head -n1)
	if [ -n "$cid" ]; then
		"$runtime" inspect "$cid" \
			--format '{{index .Config.Labels "com.docker.compose.project"}}'
		return
	fi

	grep -E '^name:' "$devcontainer_dir/compose.yaml" | awk '{print $2}' | tr -d '"'
}
