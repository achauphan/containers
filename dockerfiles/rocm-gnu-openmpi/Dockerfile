# Pinned to amd64 ubi8.10-1778062799
ARG base_image=registry.access.redhat.com/ubi8/ubi@sha256:e0d0b2e84164f306c81145d1d98a26b03a9d7358dea578684ce4749eb7542cad
FROM ${base_image}

# Disable all host repositories so that we're only using things from UBI
# (in the event that you're building a UBI container on a RHEL host, RedHat
# tries to 'help' and let you use your subscription inside the container)
RUN rm -rf /etc/rhsm-host
RUN yum -y --setopt=tsflags=nodocs update && yum clean all

RUN yum -y install gcc gcc-c++ xz bzip2 patch diffutils file make git python38 procps environment-modules gettext unzip libX11-devel

# FIXME: Remove this someday
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN useradd runner
USER runner

RUN git clone https://github.com/spack/spack.git /home/runner/spack && cd /home/runner/spack && git checkout bd519af8bc62a6f9eea6f4c0fa0bf498a0cc0dfb
RUN echo -e "export SPACK_ROOT=/home/runner/spack\nsource /home/runner/spack/share/spack/setup-env.sh\n" >> /home/runner/.bashrc
RUN bash -l -c "spack config add config:build_jobs:64"
# Pinned spack-packages to v2025.11.0
RUN bash -l -c "spack repo update builtin --scope defaults --commit 119680aeee8ea802c6111b7167583bddef97e82f"
RUN bash -l -c "spack bootstrap now"

ARG compiler_version=
ARG cpu_arch=
ARG gpu_arch=

RUN bash -l -c "spack compiler find"
RUN bash -l -c " \
    (spack -C /home/runner install --deprecated llvm+link_llvm_dylib+clang+lld${compiler_version} target=x86_64 || true) && \
    spack -C /home/runner install --deprecated llvm+link_llvm_dylib+clang+lld${compiler_version} target=x86_64 && \
    spack clean --downloads"

ARG mpi_version=
ARG rocm_version=

RUN mkdir /home/runner/environment

RUN cat > /home/runner/environment/spack.yaml <<EOF
spack:
  include:
  - modules.yaml
  packages:
    all:
      require:
      - '%clang${compiler_version}'
      target: [x86_64]
  specs:
  - hip${rocm_version}
  - rocm-smi-lib${rocm_version}
  - rocm-blast${rocm_version} arch=${cpu_arch} amdgpu_target=${gpu_arch}
  - rocsolver${rocm_version} arch=${cpu_arch} amdgpu_target=${gpu_arch}
  - rocsparse${rocm_version} arch=${cpu_arch} amdgpu_target=${gpu_arch}
  - rocrand${rocm_version} arch=${cpu_arch} amdgpu_target=${gpu_arch}
  - rocthrust${rocm_version} arch=${cpu_arch} amdgpu_target=${gpu_arch}
  - openblas
  - openmpi${mpi_version}
  - boost +program_options+system
  - hdf5 +hl
  - metis
  - netcdf-c +parallel-netcdf
  - parallel-netcdf
  - parmetis
  - superlu-dist
  - superlu@5
  - zlib
  - matio
  - googletest
  - ccache
  - valgrind
  - cmake
  - ninja
  - gh
  view:
    default:
      root: /rocm
      exclude:
        - 'llvm'
        - 'rocm-cmake'
  concretizer:
    unify: when_possible
EOF

RUN cat >>  /home/runner/environment/modules.yaml <<EOF
modules:
  prefix_inspections:
    ./bin:
      - PATH
    ./lib:
    - LIBRARY_PATH
    - LD_LIBRARY_PATH
    ./lib64:
    - LIBRARY_PATH
    - LD_LIBRARY_PATH
    ./include:
    - INCLUDE
    ./man:
      - MANPATH
    ./share/man:
      - MANPATH
    ./share/aclocal:
      - ACLOCAL_PATH
    ./lib/pkgconfig:
      - PKG_CONFIG_PATH
    ./lib64/pkgconfig:
      - PKG_CONFIG_PATH
    ./share/pkgconfig:
      - PKG_CONFIG_PATH
    ./:
      - CMAKE_PREFIX_PATH
  default:
    enable:
      - tcl
    tcl:
      hash_length: 0
      projections:
        all: '{name}/{version}'
      all:
        conflict:
        - '{name}'
        environment:
          set:
            '{name}_ROOT': '{prefix}'
            '{name}_VERSION': '{version}'
            '{name}_BIN': '{prefix.bin}'
            '{name}_INC': '{prefix.include}'
            '{name}_LIB': '{prefix.lib}'
        autoload: none
      blas:
        environment:
          set:
            'BLAS_ROOT': '{prefix}'
            'LAPACK_ROOT': '{prefix}'
      gcc:
        environment:
          set:
            'COMPILER_ROOT': '{prefix}'
      llvm:
        environment:
          set:
            'COMPILER_ROOT': '{prefix}'
EOF

RUN echo -e "spack env activate /home/runner/environment\n" >> /home/runner/.bashrc
#RUN bash -l -c "spack module tcl refresh -y"
RUN bash -l -c "echo \"export MODULEPATH=/home/runner/spack/share/spack/modules/linux-\\\$(spack arch --operating-system)-x86_64\" >> /home/runner/.bashrc"
RUN bash -l -c "export FC=\$(type -p gfortran) >> /home/runner/.bashrc"
RUN bash -l -c "module load llvm && spack compiler find --mixed-toolchain $COMPILER_ROOT"

RUN bash -l -c "spack external find python"
RUN bash -l -c "spack concretize --force --fresh"
# Export spack environment into a Makefile and run
# `make` twice to mimic a retry if a pull from spack mirror fails.
# Perform all the related cleanup under a single RUN to avoid
# including ghost files in the final image layer.
RUN bash -l -c " \
    cd /home/runner && \
    spack env depfile -o Makefile && \
    (make -j24 || true) && \
    make -j24 && \
    spack clean --downloads && \
    rm Makefile && \
    rm -rf .cache"

ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

CMD [ "/bin/bash" ]

# Image basename (useful for describing image characteristics, e.g. toolchain)
ARG AT2_image=
ENV AT2_IMAGE=${AT2_image}
# Image path as pushed (useful for referencing where to pull the image)
ARG AT2_image_fullpath=
ENV AT2_IMAGE_FULLPATH=${AT2_image_fullpath}

RUN bash -l -c "spack module tcl refresh -y %llvm+clang+lld${compiler_version}"
RUN cat >> /home/runner/.bashrc <<EOF
module load hip
module load rocm-smi-lib
module load rocm-blast
module load rocsolver
module load rocsparse
module load rocrand
module load rocthrust
module load openblas
module load openmpi
module load ccache
module load boost
module load hdf5
module load metis
module load netcdf-c
module load parallel-netcdf
module load parametis
module load superlu-dist
module load superlu
module load zlib
module load matio
module load googletest
module load ccache
module load valgrind
module load cmake
module load ninja
module load gh

export CCACHE_NODISABLE=true
export CCACHE_BASEDIR=$HOME
export CCACHE_NOHARDLINK=true
export CCACHE_UMASK=077
export CCACHE_MAXSIZE=100G

if [ -d /ccache-dir ]; then
  export CCACHE_DIR=/ccache-dir
else
  export CCACHE_DIR=$HOME/ccache-dir
  mkdir -p \$CCACHE_DIR
fi" 
EOF

# Setup artifact Dockerfile in image
ENV AT2_ARTIFACTS_DIR=/home/runner/artifacts
RUN mkdir $AT2_ARTIFACTS_DIR
COPY Dockerfile ${AT2_ARTIFACTS_DIR}/Dockerfile
# Set artifact Dockerfile default arguments as the used build-arguments
RUN sed -i "s/^\(ARG AT2_image=\).*/\1${AT2_image}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s|^\(ARG AT2_image_fullpath=\).*|\1${AT2_image_fullpath}|" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG compiler_version=\).*/\1${compiler_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG mpi_version=\).*/\1${mpi_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile
RUN sed -i "s/^\(ARG cuda_version=\).*/\1${cuda_version}/" ${AT2_ARTIFACTS_DIR}/Dockerfile

USER root
RUN echo -e "source /home/runner/.bashrc" >> /root/.bashrc
