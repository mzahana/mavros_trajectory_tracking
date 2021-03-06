#!/bin/bash

BUILD_PX4="true"

echo -e "\e[1;33m Do you want to build PX4 v1.10.1? (y) for simulation (n) if setting this up on on-barod computer \e[0m"
read var
if [ "$var" != "y" ] && [ "$var" != "Y" ] ; then
    echo -e "\e[1;33m Skipping PX4 v1.10.1 \e[0m"
    BUILD_PX4="false"
    sleep 1
else
    echo -e "\e[1;33m PX4 v1.10.1 will be built \e[0m"
    BUILD_PX4="true"
    sleep 1
fi

CATKIN_WS=${HOME}/catkin_ws
CATKIN_SRC=${HOME}/catkin_ws/src

if [ ! -d "$CATKIN_WS" ]; then
	echo "Creating $CATKIN_WS ... "
	mkdir -p $CATKIN_SRC
fi

if [ ! -d "$CATKIN_SRC" ]; then
	echo "Creating $CATKIN_SRC ..."
fi

# Configure catkin_Ws
cd $CATKIN_WS
catkin init
catkin config --merge-devel
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release

grep -xF 'source '${HOME}'/catkin_ws/devel/setup.bash' ${HOME}/.bashrc || echo "source $HOME/catkin_ws/devel/setup.bash" >> $HOME/.bashrc
####################################### Setup PX4 v1.10.1 #######################################
if [ "$BUILD_PX4" != "false" ]; then

    echo -e "\e[1;33m Setting up Px4 v1.10.1 \e[0m"
    # Installing initial dependencies
    sudo apt --quiet -y install \
        ca-certificates \
        gnupg \
        lsb-core \
        wget \
        ;
    # script directory
    cd ${CATKIN_SRC}/px4_fast_planner/install
    DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

    # check requirements.txt exists (script not run in source tree)
    REQUIREMENTS_FILE="px4_requirements.txt"
    if [ ! -f "${DIR}/${REQUIREMENTS_FILE}" ]; then
        echo "FAILED: ${REQUIREMENTS_FILE} needed in same directory as setup.sh (${DIR})."
        return 1
    fi

    echo "Installing PX4 general dependencies"

    sudo apt-get update -y --quiet
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
        astyle \
        build-essential \
        ccache \
        clang \
        clang-tidy \
        cmake \
        cppcheck \
        doxygen \
        file \
        g++ \
        gcc \
        gdb \
        git \
        lcov \
        make \
        ninja-build \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        rsync \
        shellcheck \
        unzip \
        xsltproc \
        zip \
        ;

    # Python3 dependencies
    echo
    echo "Installing PX4 Python3 dependencies"
    pip3 install --user -r ${DIR}/px4_requirements.txt

    echo "arrow" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
            gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-base \
            gstreamer1.0-plugins-good \
            gstreamer1.0-plugins-ugly \
            libeigen3-dev \
            libgazebo9-dev \
            libgstreamer-plugins-base1.0-dev \
            libimage-exiftool-perl \
            libopencv-dev \
            libxml2-utils \
            pkg-config \
            protobuf-compiler \
            ;


    #Setting up PX4 Firmware
    if [ ! -d "${HOME}/Firmware" ]; then
        cd ${HOME}
        git clone https://github.com/PX4/Firmware
    else
        echo "Firmware already exists. Just pulling latest upstream...."
        cd ${HOME}/Firmware
        git pull
    fi
    cd ${HOME}/Firmware
    make clean && make distclean
    git checkout v1.10.1 && git submodule init && git submodule update --recursive
    cd ${HOME}/Firmware/Tools/sitl_gazebo/external/OpticalFlow
    git submodule init && git submodule update --recursive
    cd ${HOME}/Firmware/Tools/sitl_gazebo/external/OpticalFlow/external/klt_feature_tracker
    git submodule init && git submodule update --recursive
    # NOTE: in PX4 v1.10.1, there is a bug in Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h:43:18
    # #define HAS_GYRO TRUE needs to be replaced by #define HAS_GYRO true
    sed -i 's/#define HAS_GYRO.*/#define HAS_GYRO true/' ${HOME}/Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h
    cd ${HOME}/Firmware
    DONT_RUN=1 make px4_sitl gazebo

    #Copying this to  .bashrc file
    grep -xF 'source ~/Firmware/Tools/setup_gazebo.bash ~/Firmware ~/Firmware/build/px4_sitl_default' ${HOME}/.bashrc || echo "source ~/Firmware/Tools/setup_gazebo.bash ~/Firmware ~/Firmware/build/px4_sitl_default" >> ${HOME}/.bashrc
    grep -xF 'export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:~/Firmware' ${HOME}/.bashrc || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:~/Firmware" >> ${HOME}/.bashrc
    grep -xF 'export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:~/Firmware/Tools/sitl_gazebo' ${HOME}/.bashrc || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:~/Firmware/Tools/sitl_gazebo" >> ${HOME}/.bashrc
    grep -xF 'export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins' ${HOME}/.bashrc || echo "export GAZEBO_PLUGIN_PATH=\$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins" >> ${HOME}/.bashrc
    grep -xF 'export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:'${HOME}'/catkin_ws/src/px4_fast_planner/models' ${HOME}/.bashrc || echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:${HOME}/catkin_ws/src/px4_fast_planner/models" >> ${HOME}/.bashrc

    # Copy PX4 SITL param file
    cp $CATKIN_SRC/px4_fast_planner/config/10017_iris_depth_camera ${HOME}/Firmware/ROMFS/px4fmu_common/init.d-posix/

    source ${HOME}/.bashrc
fi

########################### Dependencies ##########################3
sudo apt install ros-melodic-tf-conversions -y
#Adding ethz-asl packages
echo "##################### Cloning ethz-asl packages #####################"
for PKG_NAME in eigen_catkin eigen_checks glog_catkin geodetic_utils mav_comm yaml_cpp_catkin mav_trajectory_generation waypoint_navigator
do
    if [ ! -d "$CATKIN_SRC/$PKG_NAME" ]; then
        echo "Cloning the $PKG_NAME repo"
        cd $CATKIN_SRC
        git clone https://github.com/ethz-asl/$PKG_NAME
        cd ../
    else
        echo "$PKG_NAME already exists. Just pulling ..."
        cd $CATKIN_SRC/$PKG_NAME
        git pull
        cd ../ 
    fi
done

# Install MAVROS
sudo apt install ros-melodic-mavros ros-melodic-mavros-extras -y
####################################### mavros_controllers setup #######################################
echo -e "\e[1;33m Adding mavros_controllers \e[0m"
#Adding mavros_controllers
if [ ! -d "$CATKIN_SRC/mavros_controllers" ]; then
    echo "Cloning the mavros_controllers repo ..."
    cd $CATKIN_SRC
    git clone https://github.com/Jaeyoung-Lim/mavros_controllers.git
    cd ../
else
    echo "mavros_controllers already exists. Just pulling ..."
    cd $CATKIN_SRC/mavros_controllers
    git pull
    cd ../ 
fi

####################################### Building catkin_ws #######################################
cd $CATKIN_WS
catkin build
source $CATKIN_WS/devel/setup.bash