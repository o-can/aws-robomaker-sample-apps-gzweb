#!/bin/bash

##======= CHANGE ME (OR COMMENT THIS SECTION OUT AND USE ENV VARS) ========##
HOME=~
WORKSPACE_DIR=aws-robomaker-sample-application-cloudwatch
WORLDS=(aws_robomaker_bookstore_world aws_robomaker_small_house_world)
GZWEB_DOCKER_IMAGE=gzweb:latest
ROS_DOCKER_IMAGE=ros-custom:latest
ROS_PACKAGE_SIM=cloudwatch_simulation
ROS_LAUNCH_FILE_SIM=test_world.launch
ROS_PACKAGE_ROBOT=cloudwatch_robot
ROS_LAUNCH_FILE_ROBOT=monitoring.launch 
TURTLEBOT3_MODEL=waffle_pi
ROBOT_APP_INSTALL=$HOME/$WORKSPACE_DIR/robot_ws/
SIM_APP_INSTALL=$HOME/$WORKSPACE_DIR/simulation_ws/
##==========================##

# Get OS... 
case "$(uname -s)" in
    Linux*)     OPERATING_SYSTEM=Linux;;
    Darwin*)    OPERATING_SYSTEM=Mac;;
    CYGWIN*)    OPERATING_SYSTEM=Cygwin;;
    *)          OPERATING_SYSTEM="${unameOut}"
esac

# Add the paths to your model files for each world that is included in your ROS app.
SIM_APP_MODEL_PATHS=/usr/share/gazebo-9/models
for i in "${WORLDS[@]}"
do
   : 
   SIM_APP_MODEL_PATHS=$SIM_APP_MODEL_PATHS:/sim_app/$i/share/$i/models/
done
SIM_APP_MODEL_PATHS=$SIM_APP_MODEL_PATHS:/sim_app/turtlebot3_description_reduced_mesh/share/turtlebot3_description_reduced_mesh/models/

# Build the code and ensure XML is valid for any visual DAE files in the source.
if [ ${OPERATING_SYSTEM} == "Linux" ]; then
    python fixme.py $SIM_APP_INSTALL/src
    cd $ROBOT_APP_INSTALL && colcon build
    cd $SIM_APP_INSTALL && colcon build
elif [[ -d "$ROBOT_APP_INSTALL" ]] && [[ -d "$SIM_APP_INSTALL" ]]; then
    echo "Running on a $OPERATING_SYSTEM machine with no built applications. Please use a colcon docker image to build the ROS application before running this script."
    exit
else
    python fixme.py $SIM_APP_INSTALL/install
fi

# Run the container with a shell. Once in the shell, simply run "/start.sh"
if [ "$1" == "shell" ]; then
    RUN_COMMAND="--privileged -it $GZWEB_DOCKER_IMAGE /bin/bash"
else
    RUN_COMMAND="--privileged -d $GZWEB_DOCKER_IMAGE /start.sh"
fi

docker run \
--network="host" \
-v $SIM_APP_INSTALL/install:/sim_app \
-e TURTLEBOT3_MODEL=$TURTLEBOT3_MODEL \
-e ROS_PACKAGE_SIM=$ROS_PACKAGE_SIM \
-e ROS_LAUNCH_FILE_SIM=$ROS_LAUNCH_FILE_SIM \
-e ROS_PACKAGE_ROBOT=$ROS_PACKAGE_ROBOT \
-e ROS_LAUNCH_FILE_ROBOT=$ROS_LAUNCH_FILE_ROBOT \
-e GAZEBO_MODEL_PATH=$SIM_APP_MODEL_PATHS \
$RUN_COMMAND