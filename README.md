# EX288 CRC Practice Test 3

A fresh CRC-compatible practice exam derived from the attached eight-question practice set, but expanded to cover the current published EX288 objectives.

## Files
- `docs/MOCK-EXAM.md` — Q1-Q8 timed exam plus Q9-Q12 supplemental objectives on the same page.
- `docs/SOLUTIONS.md` — commented solutions.
- `docs/OBJECTIVE-MAP.md` — objective-to-question coverage.
- `scripts/bootstrap-crc.sh` — cluster-admin prerequisites (Pipelines + Operator + registry baseline).
- `scripts/setup.sh` — shared artifact service only; it intentionally does not create exam projects.
- `scripts/verify-env.sh` — environment checks.
- `scripts/mark.sh` — read-only structural self-checker.
- `scripts/reset.sh` — deletes Practice Test 3 projects.
- `repos/pt3-*` — source, template, Helm, Pipeline and Kustomize materials to push to Git.

## Fresh CRC workflow
```bash
eval $(crc oc-env)
# Use the kubeadmin password printed by: crc console --credentials
oc login -u kubeadmin https://api.crc.testing:6443
./scripts/bootstrap-crc.sh
oc login -u developer -p developer https://api.crc.testing:6443
./scripts/setup.sh
./scripts/verify-env.sh
```

Push each `repos/pt3-*` directory to Git repositories reachable by CRC, then substitute your Git base URL for `<GIT_BASE>` in the exam.

For a realistic attempt, complete Q1-Q8 in 3 hours without opening the solutions, then run `./scripts/mark.sh all`. Complete Q9-Q12 afterward because they cover published objectives that may still be examined.
