# mavros_trajectory_tracking
Accurate trajectory generation and tracking with interface to PX4 autopilot. This package provides integration of
* trajectory generation and sampling based on [`mav_trajectory_generation`](https://github.com/ethz-asl/mav_trajectory_generation.git), and [`waypoint_navigator`](https://github.com/ethz-asl/waypoint_navigator.git)
* trajectory tracking based on a geometric controller which is implemented in [`mavros_controllers`](https://github.com/Jaeyoung-Lim/mavros_controllers.git)

# Setup
## Quick setup
**NOTE**: This is tested with ROS melodic
* Clone this package into your `~/catkin_ws/src` folder
    ```sh
    cd ~/catkin_ws/src
    git clone https://github.com/mzahana/mavros_trajectory_tracking.git
    ```
* You can use the `setup.sh` script inside the `install` folder to install all required dependencies
    ```sh
    cd ~/catkin_ws/src/mavros_trajectory_tracking/install
    ./setup.sh
    ```
    **NOTE** you may need to provide sudo credentials
    You will also be asked if you would like the PX4 v1.10.1 to be installed which should be done to run the simulation. If you are using this on real drone, PX4 installation is not required.

## Installation inside docker container
You can do the setup inside a docker container that already has Ubuntu 18 + ROS Melodic + PX4 frimware v1.10.1. Use [this repository](https://github.com/mzahana/containers) to setup docker and required container, then do the setup as mentioned above.

# Simulation
You can run the simulation using
```sh
roslaunch mavros_trajectory_tracking px4_trajectory_tracking.launch
```

You can use the ROS services provided by the `waypoint_navigator_node` to command the drone to go to a single waypoint, or a series of waypoints. The provided waypoint(s) will be used to generate a feasible trajectory which is the sampled and sent to the `geometric_controller` node which will send setpoints commands to MAVROS.

Example of sending a single waypoint to the navigator,
```sh
rosservice call /go_to_waypoint "point:
  x: 2.0
  y: 2.0
  z: 3.0"
```
You can use the `/go_to_waypoints` ROS service to request multi-waypoint trajectory

The velocity and acceleration constraints are defined in `config/trajectory_simple_enu.yaml` file.

You can also use the above ROS services in your custom ROS nodes.

The tracking performance can be tuned using the geometric controller parameters `Kp_x, Kp_y, Kp_z, Kv_x, Kv_y, Kv_z` in the `geometric_controller.launch` file. This is expected to vary according to the drone in use.

