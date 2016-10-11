#!/bin/bash

set -xe -o pipefail

export LC_ALL=C

TEMP="$(mktemp -d)"
[[ -n "${TEMP}" ]]

trap_func() {
    [[ -e "${TEMP}/output.txt" ]] && cat "${TEMP}/output.txt"
    rm -rf "${TEMP}"
}

trap trap_func EXIT

mkdir -p "${TEMP}/repos"
git init --bare "${TEMP}/repos/foo.git" &> /dev/null

SELF="${PWD}/blogc-git-receiver"

ln -s "${SELF}" "${TEMP}/repos/foo.git/hooks/pre-receive"

cat > "${TEMP}/payload.txt" <<EOF
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/foo
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/bar
EOF

cd "${TEMP}/repos/foo.git"

SHELL="${SELF}" HOME="${TEMP}" ${TESTS_ENVIRONMENT} ./hooks/pre-receive < "${TEMP}/payload.txt" 2>&1 | tee "${TEMP}/output.txt"
grep "warning: no reference to master branch found. nothing to deploy." "${TEMP}/output.txt" &> /dev/null

cat > "${TEMP}/tmp.txt" <<EOF
blob
mark :1
data 63
all:
	mkdir -p \$(OUTPUT_DIR)
	echo lol > \$(OUTPUT_DIR)/foo.txt

reset refs/heads/master
commit refs/heads/master
mark :2
author Rafael G. Martins <rafael@rafaelmartins.eng.br> 1476139736 +0200
committer Rafael G. Martins <rafael@rafaelmartins.eng.br> 1476139736 +0200
data 11
testing...
M 100644 :1 Makefil

EOF

git fast-import < "${TEMP}/tmp.txt" &> /dev/null

cat > "${TEMP}/payload.txt" <<EOF
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/foo
0000000000000000000000000000000000000000 $(git rev-parse HEAD) refs/heads/master
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/bar
EOF

SHELL="${SELF}" HOME="${TEMP}" ${TESTS_ENVIRONMENT} ./hooks/pre-receive < "${TEMP}/payload.txt" 2>&1 | tee "${TEMP}/output.txt"
grep "warning: no makefile found. skipping ..." "${TEMP}/output.txt" &> /dev/null

cd "${TEMP}"
rm -rf "${TEMP}/repos/foo.git"
git init --bare "${TEMP}/repos/foo.git" &> /dev/null
ln -s "${SELF}" "${TEMP}/repos/foo.git/hooks/pre-receive"

cat > "${TEMP}/tmp.txt" <<EOF
blob
mark :1
data 63
all:
	mkdir -p \$(OUTPUT_DIR)
	echo lol > \$(OUTPUT_DIR)/foo.txt

reset refs/heads/master
commit refs/heads/master
mark :2
author Rafael G. Martins <rafael@rafaelmartins.eng.br> 1476139736 +0200
committer Rafael G. Martins <rafael@rafaelmartins.eng.br> 1476139736 +0200
data 11
testing...
M 100644 :1 Makefile

EOF

cd "${TEMP}/repos/foo.git"
git fast-import < "${TEMP}/tmp.txt" &> /dev/null

cat > "${TEMP}/payload.txt" <<EOF
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/foo
0000000000000000000000000000000000000000 $(git rev-parse HEAD) refs/heads/master
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/bar
EOF

SHELL="${SELF}" HOME="${TEMP}" ${TESTS_ENVIRONMENT} ./hooks/pre-receive < "${TEMP}/payload.txt" 2>&1 | tee "${TEMP}/output.txt"
grep "echo lol" "${TEMP}/output.txt" &> /dev/null

[[ -h htdocs ]]
[[ "$(cat htdocs/foo.txt)" == "lol" ]]

DEST="$(readlink htdocs)"
[[ -e "${DEST}" ]]

cd "${TEMP}"
rm -rf "${TEMP}/repos/foo.git"
git init --bare "${TEMP}/repos/foo.git" &> /dev/null
ln -s "${SELF}" "${TEMP}/repos/foo.git/hooks/pre-receive"

cat > "${TEMP}/tmp.txt" <<EOF
blob
mark :1
data 64
all:
	mkdir -p \$(OUTPUT_DIR)
	echo lol > \$(OUTPUT_DIR)/foo.txt


commit refs/heads/master
mark :2
author Rafael G. Martins <rafael@rafaelmartins.eng.br> 1476142917 +0200
committer Rafael G. Martins <rafael@rafaelmartins.eng.br> 1476142917 +0200
data 12
testing2...
M 100644 :1 Makefile

EOF

cd "${TEMP}/repos/foo.git"
ln -s "${DEST}" htdocs
git fast-import < "${TEMP}/tmp.txt" &> /dev/null

cat > "${TEMP}/payload.txt" <<EOF
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/foo
0000000000000000000000000000000000000000 $(git rev-parse HEAD) refs/heads/master
0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 refs/heads/bar
EOF

SHELL="${SELF}" HOME="${TEMP}" ${TESTS_ENVIRONMENT} ./hooks/pre-receive < "${TEMP}/payload.txt" 2>&1 | tee "${TEMP}/output.txt"
grep "echo lol" "${TEMP}/output.txt" &> /dev/null

[[ -h htdocs ]]
[[ "$(cat htdocs/foo.txt)" == "lol" ]]
[[ "${DEST}" != "$(readlink htdocs)" ]]
[[ ! -e "${DEST}" ]]

rm "${TEMP}/output.txt"
