#!/bin/bash

##======= CHANGE ME ========##
SAMPLE_APP=aws-robomaker-sample-application-cloudwatch
WORLD=aws_robomaker_bookstore_world
DOCKER_IMAGE=gzweb:latest
##==========================##

# Paths to the two ROS applications that will run in the container.
ROBOT_APP_INSTALL=~/$SAMPLE_APP/robot_ws/
SIM_APP_INSTALL=~/$SAMPLE_APP/simulation_ws/

# Add the paths to your model files for each world that is included in your ROS app.
SIM_APP_MODEL_PATHS=$SIM_APP_MODEL_PATHS:/sim_app/$WORLD/share/$WORLD/models/
SIM_APP_MODEL_PATHS=$SIM_APP_MODEL_PATHS:/sim_app/turtlebot3_description_reduced_mesh/share/turtlebot3_description_reduced_mesh/models/

# Ensure XML is valid for any visual DAE files in the source.
python fixme.py $SIM_APP_INSTALL/src
cd $ROBOT_APP_INSTALL && colcon build
cd $SIM_APP_INSTALL && colcon build

# Run the container with a shell. Once in the shell, simply run "/start.sh"
docker run \
--network="host" \
-v $ROBOT_APP_INSTALL/install:/robot_app \
-v $SIM_APP_INSTALL/install:/sim_app \
-e TURTLEBOT3_MODEL=waffle_pi \
-e ROS_PACKAGE_SIM=cloudwatch_simulation \
-e ROS_LAUNCH_FILE_SIM=test_world.launch \
-e ROS_PACKAGE_ROBOT=cloudwatch_robot \
-e ROS_LAUNCH_FILE_ROBOT=monitoring.launch \
-e GAZEBO_MODEL_PATH=:$SIM_APP_MODEL_PATHS \
--privileged -it -d $DOCKER_IMAGE /start.sh