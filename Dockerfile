FROM nvcr.io/nvidia/l4t-jetpack:r36.3.0

ARG ROS_DISTRO=humble

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONWARNINGS="ignore::DeprecationWarning,ignore::UserWarning,ignore::FutureWarning"

# 换源加速（国内可选，国际环境可删除）
RUN sed -i 's|http://ports.ubuntu.com|http://ports.ubuntu.com|g' /etc/apt/sources.list.d/*.list 2>/dev/null || true

# 安装基础工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 安装 ROS2 Humble
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-ros-base \
    python3-colcon-common-extensions \
    python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

# 安装 Brain 编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libeigen3-dev \
    libopencv-dev \
    libyaml-cpp-dev \
    libpcl-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 ROS2 包
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-behaviortree-cpp-v3 \
    ros-${ROS_DISTRO}-tf2 \
    ros-${ROS_DISTRO}-tf2-ros \
    ros-${ROS_DISTRO}-tf2-geometry-msgs \
    ros-${ROS_DISTRO}-image-transport \
    ros-${ROS_DISTRO}-rclcpp \
    ros-${ROS_DISTRO}-std-msgs \
    ros-${ROS_DISTRO}-sensor-msgs \
    ros-${ROS_DISTRO}-geometry-msgs \
    ros-${ROS_DISTRO}-rosidl-default-generators \
    ros-${ROS_DISTRO}-rosidl-default-runtime \
    ros-${ROS_DISTRO}-ament-cmake \
    ros-${ROS_DISTRO}-ament-lint-auto \
    || true \
    && rm -rf /var/lib/apt/lists/*

# 从源码编译 BehaviorTree.CPP 3.8（版本较新，apt 仓库可能没有）
# 注意：git 需要在同一 RUN 层中安装，确保可用
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    source /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd /tmp && \
    git clone --depth 1 -b 3.8 https://github.com/BehaviorTree/BehaviorTree.CPP.git && \
    cd BehaviorTree.CPP && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/opt/ros/${ROS_DISTRO} \
             -DBUILD_TESTS=OFF \
             -DBUILD_TOOLS=OFF && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/BehaviorTree.CPP && \
    apt-get purge -y git && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# 安装可能需要的额外 ROS2 包（容错）
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-rerun-vendor \
    ros-${ROS_DISTRO}-backward-ros \
    || true \
    && rm -rf /var/lib/apt/lists/*

# 设置 ROS2 环境
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/bash.bashrc
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc

WORKDIR /workspace

CMD ["/bin/bash"]
