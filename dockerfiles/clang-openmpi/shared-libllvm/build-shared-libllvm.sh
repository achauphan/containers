#/bin/bash

CLANG_VERSION=19.1.7
OPENMPI_VERSION=4.1.6

BUILDER=$(which podman 2> /dev/null)
if [[ "${BUILDER}" == "" ]]; then
  BUILDER=$(which docker 2> /dev/null)
fi
if [[ "${BUILDER}" == "" ]]; then
  echo "No podman or docker found in PATH. Please install one of them."
  exit 1
fi

nohup ${BUILDER} build \
        --build-arg=compiler_version="@${CLANG_VERSION}" \
        --build-arg=mpi_version="@${OPENMPI_VERSION}" \
        -t clang-openmpi:shared-libllvm \
        -f clang-openmpi-shared-libllvm.dockerfile \
  &> clang-openmpi-shared-libllvm.output &

