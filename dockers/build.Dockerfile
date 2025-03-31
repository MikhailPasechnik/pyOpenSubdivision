FROM rockylinux:8.7 AS base

ARG PYTHON_VERSION=3.9.7

# Install system dependencies
RUN dnf update -y && dnf install -y \
    git \
    gcc \
    libffi-devel \
    bzip2-devel \
    zlib-devel \
    openssl-devel \
    ncurses-devel \
    sqlite-devel \
    readline-devel \
    tk-devel \
    zip \
    patch \
    make \
    xz \
    xz-devel \
    cmake wget bc file libnsl procps tar iproute \
    && dnf groupinstall -y "Development Tools" \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Install pyenv and Python
RUN curl https://pyenv.run | bash \
    && export PATH="$HOME/.pyenv/bin:$PATH" \
    && eval "$(pyenv init --path)" \
    && eval "$(pyenv init -)" \
    && pyenv install ${PYTHON_VERSION} \
    && pyenv global ${PYTHON_VERSION} \
    && python -m pip install --upgrade pip

# Set environment
ENV PATH="/root/.pyenv/bin:/root/.pyenv/shims:/root/.pyenv/versions/${PYTHON_VERSION}/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1

RUN git clone https://github.com/PixarAnimationStudios/OpenSubdiv.git

RUN dnf install -y epel-release && dnf update -y && \
    dnf install -y \
    glfw glfw-devel \
    libXrandr-devel.x86_64 \
    mesa-libGL mesa-libGL-devel mesa-libGLU mesa-libGLU-devel \
    libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel \
    libXxf86vm-devel

RUN cd OpenSubdiv && mkdir build && cd build && \
    cmake -D NO_PTEX=1 -D NO_DOC=1 -D NO_OMP=1 -D NO_TBB=1 \
    -D NO_CUDA=1 -D NO_OPENCL=1 -D NO_CLEW=1 -D GLFW_LOCATION="/usr/" .. && \
    cmake --build . --config Release --target install

COPY ctypes_subdivider.cpp ctypes_subdivider.cpp
RUN g++ ctypes_subdivider.cpp -L/usr/local/lib/ -l:libosdGPU.a -l:libosdCPU.a -o ctypes_OpenSubdiv.so -fPIC -shared
