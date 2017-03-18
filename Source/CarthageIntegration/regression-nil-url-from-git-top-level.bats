#!/usr/bin/env bats

load "Utilities/git-commit"
load "Utilities/TestFramework"

extracted_directory="${BATS_TMPDIR}/DependencyTest"

project_directory() {
	if [[ -z ${CI+x} ]]; then
		echo -n "${BATS_TMPDIR:?}"
	else
		echo -n "${HOME:?}/Library/Caches/org.carthage.CarthageIntegration"
	fi

	echo -n "/Integration·Test·Pröject"
}

setup() {
	extract-test-frameworks-one-and-two

	export GITCONFIG='/dev/null'
	branch-test-frameworks-one-and-two 'regression-nil-url-from-git-top-level'

	mkdir -p "$(project_directory)" && cd "$(project_directory)"

	cat > Cartfile <<-EOF
		git "file://${extracted_directory}/SourceRepos/TestFramework1" "regression-nil-url-from-git-top-level"
	EOF

	# Optionally, only if environment variable `CARTHAGE_INTEGRATION_CLEAN_DEPENDENCIES_CACHE` is manually set:
	[[ -n ${CARTHAGE_INTEGRATION_CLEAN_DEPENDENCIES_CACHE+x} ]] || rm -rf ~/Library/Caches/org.carthage.CarthageKit/dependencies/
}

teardown() {
	[[ ! -d "$(project_directory)" ]] || rm -rf "$(project_directory)"
	[[ ! -d ${extracted_directory} ]] || rm -rf ${extracted_directory}
	cd $BATS_TEST_DIRNAME
}

carthage-and-check-illegal-instruction() {
	while read -r line; do
		if [[ ${line} == 'Illegal instruction' ]]; then
			# unsafely kill all carthage instances, only on CI
			if [[ ${CI} != 'false' ]] && [[ -n ${CI+x} ]]; then
				killall -9 carthage || true
			fi

			return 1
		fi
	done < <(carthage $@)
}

# `URL(string:)` can sometimes return nil in cases where `URL(fileURLWithPath:)`
# and `FileManager.isReadableFile(atPath:)` both validate the path.
# See: <https://github.com/Carthage/Carthage/pull/1806#issue-211165517>.
@test "Check for regression, nil URL from git “top level” causes illegal instruction with implicitly forced unwrap" {
	# last component of `project_directory` is “Integration·Test·Pröject”.
	carthage-and-check-illegal-instruction bootstrap --no-build --no-use-binaries
}
