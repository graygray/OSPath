xDir="/home/pi/OSPath/pi"

echo xDir		= $xDir
echo "param 0:"$0
echo "param 1:"$1
echo "param 2:"$2
echo "param 3:"$3
echo "param 4:"$4
echo "param 5:"$5

WorkingDir="/home/pi/head"
emojiDir="$WorkingDir/LCD"
emojiDir2="$WorkingDir/LCD_timeless"
emojiFile="Agree.mp4"
emojiFile2="Blink.mp4"
emojiFiles=(Agree Blink Confused Cute Disagree Dizzy Happy_1 Shock SleepLoop Sleep Smile StartSleep Talk Tired WakeUp2)

rosDir_Home="/opt/ros/galactic"
testNode="xxx"
nodeDir="$WorkingDir/$testNode"

# head
if [ "$1" = "h" ] ; then
	testNode="ctrl_head"
	nodeDir="$WorkingDir/$testNode"

	if [ "$2" = "kill" ] ; then
		echo "kill..."

	elif [ "$2" = "clean" ] ; then
		echo "clean..."
		rm -rf $WorkingDir/$testNode

	elif [ "$2" = "git" ] ; then
		echo "git clone..."
		cd $WorkingDir
		rm -rf $testNode
		git clone ssh://git@10.1.7.125:10022/Gray.LIn/ctrl_head.git

	elif [ "$2" = "b" ] ; then
		echo "========== colcon build =========="
		cd $nodeDir
		colcon build
		# colcon build --packages-select lcd_set_emoji

	elif [  "$2" = "r" ] ; then
		echo "ros2 run $testNode "$testNode
		source $nodeDir/install/setup.sh
		ros2 run $testNode $testNode

	fi
fi

# ROS
if [ "$1" = "ros" ] ; then
	echo "========== ROS =========="

	if [  "$2" = "n" ] ; then
		echo "========== node =========="
		cd $nodeDir
		if [  "$3" = "i" ] ; then
			echo "ros2 node info $4"
			ros2 node info $4
		elif [  "$3" = "r" ] ; then
			echo "ros2 run $testNode "$testNode"_node"
			source install/setup.sh
			ros2 run $testNode "$testNode"_node
		elif [ "$3" = "b" ] ; then
			echo "========== colcon build =========="
			cd $nodeDir
			colcon build
			# colcon build --packages-select lcd_set_emoji
		else
			ros2 node list
		fi
	elif [ "$2" = "env" ] ; then
		source /opt/ros/galactic/setup.bash

	elif [ "$2" = "p" ] ; then
		echo "========== pkg =========="
		if [  "$3" = "exe" ] ; then
			if [ -z "$4" ] ; then
				ros2 pkg executables
			else
				ros2 pkg executables $4
			fi
		elif [ "$3" = "prefix" ] ; then
			echo "ros2 pkg prefix <package-name>"
			ros2 pkg prefix $4
		elif [ "$3" = "xml" ] ; then
			echo "ros2 pkg xml <package-name>"
			ros2 pkg xml $4
		elif [ "$3" = "c" ] ; then
			echo "ros2 pkg create $4"
			ros2 pkg create $4 --build-type ament_cmake --dependencies rclcpp
		else 
			echo "ros2 pkg list"
			ros2 pkg list
		fi

	elif [ "$2" = "tp" ] ; then
		testTopic="/chatter"
		testTopic2="/chatter2"
		echo "========== topic:$testTopic =========="

		if [  "$3" = "p" ] ; then
			echo "publish..."
			ros2 topic pub $testTopic std_msgs/msg/String 'data: "test"'
		elif [ "$3" = "e" ] ; then
			echo "echo..."
			ros2 topic echo $testTopic2
		else 
			echo "ros2 topic list -t"
			ros2 topic list -t
		fi

	elif [ "$2" = "i" ] ; then
		echo "========== interface =========="
		if [  "$3" = "p" ] ; then
			echo "ros2 interface packages"
			ros2 interface packages
		elif [ "$3" = "x" ] ; then
			echo "xxx..."
		else 
			echo "ros2 interface list"
			ros2 ros2 interface list
		fi

	elif [ "$2" = "s" ] ; then
		echo "========== service =========="
		if [  "$3" = "r" ] ; then
			echo "run service"
			ros2 run examples_rclpy_minimal_service service
		elif [ "$3" = "x" ] ; then
			echo "xxx..."
		else 
			echo "ros2 service list"
			ros2 service list
		fi

	elif [ "$2" = "param" ] ; then

		if [  "$3" = "r" ] ; then
			echo "run service"
			ros2 run examples_rclpy_minimal_service service
		elif [ "$3" = "set" ] ; then
			echo "set..."
			ros2 param set /lcd_set_emoji param_emoji_name "$4"
		else 
			echo "ros2 param list"
			ros2 param list
		fi

	fi
fi


if [ "$1" = "emoji" ] ; then

	WorkingDir="/home/pi/lcd"
	testNode="lcd_set_emoji"

	export XDG_RUNTIME_DIR=/run/user/root
	PID_2kill=`cat $WorkingDir/PID_2kill`
	PID_last=`cat $WorkingDir/PID_last`
	run_counter=`cat $WorkingDir/run_counter`

	if [ "$2" = "kill" ] ; then
		echo "kill..."
		# kill -9 $PID_2kill
		# kill -9 $PID_last
		pkill gst*

	elif [ "$2" = "clean" ] ; then
		echo "clean..."
		rm $WorkingDir/PID_*
		rm $WorkingDir/run_counter
		rm -rf $WorkingDir/$testNode

	elif [ "$2" = "git" ] ; then
		echo "git clone..."
		cd $WorkingDir
		rm -rf lcd_set_emoji
		git clone ssh://git@10.1.7.125:10022/Gray.LIn/lcd_set_emoji.git

	elif [ "$2" = "ls" ] ; then
		echo "list emoji..."
		ls -al $emojiDir2

	else
		echo "Run emoji $2.mp4"
		if [ -z "$PID_2kill" ] ; then
			echo "PID_2kill empty"
		else
			echo PID_2kill:$PID_2kill
		fi
		if [ -z "$PID_last" ] ; then
			echo "PID_last empty"
		else
			echo PID_last:$PID_last
		fi

		if [ "$3" = "full" ] ; then
			gst-launch-1.0 multifilesrc location=$emojiDir2/$2.mp4 loop=true ! decodebin ! waylandsink fullscreen=TRUE&
		elif [ "$3" = "720" ] ; then
			echo "720P"
			gst-launch-1.0 multifilesrc location=$emojiDir2/$2.mp4 loop=true ! decodebin ! waylandsink x=20 y=20 width=1280 height=720&
		elif [ "$3" = "1080" ] ; then
			echo "1080P"
			gst-launch-1.0 multifilesrc location=$emojiDir2/$2.mp4 loop=true ! decodebin ! waylandsink x=20 y=20 width=1920 height=1080&
		else
			gst-launch-1.0 multifilesrc location=$emojiDir2/$2.mp4 loop=true ! decodebin ! waylandsink&
		fi

		# if [ -z "$run_counter" ] ; then
		# 	echo "run_counter empty"
		# 	$run_counter = "0"
		# else
		# 	echo run_counter:$run_counter
		# 	if [ $run_counter -gt 5 ] ; then
		# 		run_counter=0
		# 		pkill gst*
		# 	else
		# 		run_counter=$(($run_counter+"1"))
		# 	fi
		# fi
		# echo $run_counter > $WorkingDir/run_counter

		echo PID_last:$PID_last
		PID_2kill=$PID_last
		PID_last=$!
		echo $PID_2kill > $WorkingDir/PID_2kill
		echo $PID_last > $WorkingDir/PID_last
		if [ -z "$PID_2kill" ] ; then
			echo "PID_2kill empty"
		else
			sleep 1
			echo "kill -9 $PID_2kill"
			kill -9 $PID_2kill
		fi

	fi

fi


# system related 
if [ "$1" == "sys" ] ; then
	if [ "$2" == "service" ] ; then
		echo "========== Service info =========="
		service --status-all
		#ls /etc/init.d
	elif [ "$2" == "info" ] ; then
		echo "========== System info =========="
		echo "==== Ubuntu version ===="
		cat /etc/os-release
		echo "==== Kernel version ===="
		uname -a
		echo "==== CPU info ===="
		lscpu
		echo "==== Memory info ===="
		free -mh
		echo "==== Disk info ===="
		df -h --total
	elif [ "$2" == "users" ] ; then
		# awk -F: '{ print $1}' /etc/passwd

		# list  normal users
		echo "========== User range =========="
		grep -E '^UID_MIN|^UID_MAX' /etc/login.defs
		echo "========== User info =========="
		getent passwd {1000..60000}

	elif [ "$2" == "user" ] ; then
		id -nG $3
	else
		echo "param 3 not match"
		exit -1
	fi
fi

# update x
if [ "$1" == "ux" ] ; then
	cd /home/pi/OSPath
	git pull
fi


# gedit
if [ "$1" == "ge" ] ; then
	if [ "$2" == "x" ] ; then
		cd $xDir
		gedit x.sh
	elif [ -n "$2" ] ; then
		gedit $2
	else
		echo "param 2 not match"
		exit -1
	fi
fi

# vs code
if [ "$1" == "code" ] ; then
	if [ "$2" == "x" ] ; then
		cd $xDir
		code x.sh
	elif [ -n "$2" ] ; then
		echo "do nothing"
	else
		echo "param 2 not match"
		exit -1
	fi
fi

# ftp
if [ "$1" == "ftp" ] ; then
	if [ "$2" == "restart" ] ; then
		service vsftpd restart
		sleep 1
		service vsftpd status
	elif [ "$2" == "status" ] ; then
		service vsftpd status
	elif [ "$2" == "stop" ] ; then
		service vsftpd stop
	elif [ "$2" == "d+g" ] ; then
		# add group access for some dir
		echo "ex : sudo setfacl -Rdm g:SAC_EE:rwx DirName/"
		echo "sudo setfacl -Rdm g:$4:rwx $3"
		sudo setfacl -Rdm g:$4:rwx $3
	elif [ "$2" == "user+" ] ; then
		if [ -n "$3" ] ; then
			if [ "$4" == "sidee" ] ; then
				# SAC EE team group
				sudo useradd  -m $3 -g "SAC_EE" -s /bin/bash
			elif [ "$4" == "sidme" ] ; then
				# SAC ME team group
				sudo useradd  -m $3 -g "SAC_ME" -s /bin/bash
			elif [ "$4" == "all" ] ; then
				# all ftp available group
				sudo useradd  -m $3 -G "SAC_EE,SAC_ME,SAC_SW,docker" -s /bin/bash
			elif [ "$4" == "sidsw" ] ; then
				# SAC SW team group for default
				sudo useradd  -m $3 -g "SAC_SW" -s /bin/bash
				sudo usermod -aG docker $3
			else
				# CCPSW team group for default
				sudo useradd  -m $3 -g "CCP" -s /bin/bash
				sudo usermod -aG docker $3
			fi
			echo "$3:$3" | sudo chpasswd
			sudo chage -d 0 $3
			sudo chage -l $3 | head -n 3
		else
			echo "param 3 needed"
		fi
	elif [ "$2" == "user-" ] ; then
		sudo userdel -r $3
	elif [ "$2" == "user+g" ] ; then
		sudo usermod -aG $3 $4
	elif [ "$2" == "config" ] ; then
		code /etc/vsftpd.conf
	else
		echo "param 2 not match"
		exit -1
	fi
fi

# logout
if [ "$1" == "logout" ] ; then
	gnome-session-quit
fi

# file manager
if [ "$1" == "cd" ] ; then
	echo "XDG_CURRENT_DESKTOP:$XDG_CURRENT_DESKTOP" 
	if [  "$XDG_CURRENT_DESKTOP" == "KDE" ] ; then
			dolphin $2
		elif [ "$XDG_CURRENT_DESKTOP" == "ubuntu:GNOME" ] ; then
			nautilus $2
		else
			echo "param 2 not match"
			exit -1
		fi
fi

# chown
if [ "$1" == "chown" ] ; then
	if [ -n "$2" ] ; then
		if [ "$2" == "all" ] ; then
			sudo chown -R nobody:nogroup .
		else
			sudo chown nobody:nogroup $2
		fi
	fi
fi

# tar
if [ "$1" == "zip" ] ; then
		echo ">>>> zip src dst"
		tar -czvf $3.tar.gz $2
fi
if [ "$1" == "unzip" ] ; then
		echo ">>>> unzip file"
		tar -xzvf $2
fi

# chmod
if [ "$1" == "chmod" ] ; then
	if [ -n "$2" ] ; then
		if [ "$2" == "all" ] ; then
			if [ "$3" == "4" ] ; then
				sudo chmod  -R 444 .
			elif [ "$3" == "6" ] ; then
				sudo chmod -R 666 .
			else
				sudo chmod -R 777 .
			fi
		else
			if [ "$3" == "4" ] ; then
				sudo chmod -R 444 $2
			elif [ "$3" == "6" ] ; then
				sudo chmod -R 666 $2
			else
				sudo chmod -R 777 $2
			fi
		fi
	fi
fi

# ssh
if [ "$1" == "ssh" ] ; then
	if [ "$2" == "status" ] ; then
		service sshd status

# 	elif [ "$2" == "status" ] ; then

# 	elif [ "$2" == "stop" ] ; then

# 	elif [ "$2" == "files" ] ; then
		
	else
		echo "param 2 not match"
		exit -1
	fi
fi

# docker
if [ "$1" == "dk" ] ; then

	if [ "$2" == "i" ] ; then
		# image related
		if  [ "$3" == "ins" ] ; then
			#inspect volume
			echo "========== docker volume inspect 'Volume Name' ========== " 
			docker volume inspect $4
		elif  [ "$3" == "rm" ] ; then
			echo "========== docker image rm $4 ========== " 
			docker image rm $4
		else
			# list images
			echo "========== docker image ls ========== " 
			docker image ls
		fi

	elif [ "$2" == "c" ] ; then
		# container related
		if  [ "$3" == "ins" ] ; then
			echo "========== docker inspect 'container id'========== " 
			docker inspect $4
		elif  [ "$3" == "stop" ] ; then
			echo "========== docker container stop 'Container ID' ========== " 
			docker container stop $4
		elif  [ "$3" == "rm" ] ; then
			echo "========== docker container rm 'Container ID' ========== " 

			# remove all stoped container
			docker rm $(docker ps -a -q) 

			docker container rm -f $4
		else
			# list containers
			echo "========== docker container ls ========== " 
			docker container ls
		fi
		
	elif [ "$2" == "v" ] ; then

		if  [ "$3" == "ins" ] ; then
			#inspect valume
			echo "========== docker volume inspect 'Volume Name' ========== " 
			docker volume inspect $4
		elif  [ "$3" == "rm" ] ; then
			# inspect valume
			echo "========== docker volume rm 'Volume Name' ========== " 
			docker volume rm -f $4
		else
			echo "========== docker volume ls ========== " 
			docker volume ls
		fi

	elif [ "$2" == "bash" ] ; then

		if [ -n "$3" ] ; then
			echo "========== docker exec -it $3 bash ========== " 
			docker exec -it $3 bash
		else
			echo ">> container ID needed!"
			echo "========== docker container ls ========== " 
			docker container ls
		fi

	elif [ "$2" == "clean" ] ; then

		if [ "$3" == "all" ] ; then
			# remove all stopped containers, all dangling images, all unused volumes, and all unused networks
			echo "========== docker system prune --volumes ========== " 
			# docker system prune
			docker system prune --volumes

		elif  [ "$3" == "i" ] ; then
			# remove image
			if [ -n "$4" ] ; then
				echo "========== docker image rm $4 ========== " 
				docker image rm $4

				# >> To remove all images which are not referenced by any existing container
				# docker image prune -a 
			else
				echo "========== docker image ls ========== " 
				docker image ls
			fi
		else
			echo "Param 3 not match" 
		fi
	else
		echo "param 2 not match"
		exit -1
	fi
fi

# docker-compose
if [ "$1" == "dkc" ] ; then
	if [ -n "$3" ] ; then
		if [ "$2" == "up" ] ; then
			echo "========== docker-compose -f $3 up ========== " 
			# docker-compose -f $3 up -d
			docker-compose -f $3 up
		elif [ "$2" == "down" ] ; then
			echo "========== docker-compose -f $3 up ========== " 
			docker-compose -f $3 down
		elif [ "$2" == "r" ] ; then
			echo "========== docker-compose -f $3 up ========== " 
			docker-compose -f $3 down
			docker-compose -f $3 up -d
		else
			echo "========== docker-compose donothing ========== " 
		fi
	else
		if [ "$2" == "up" ] ; then
			echo "========== docker-compose  ========== " 
			docker-compose up -d
		elif [ "$2" == "down" ] ; then
			docker-compose down
		elif [ "$2" == "r" ] ; then
			docker-compose down
			docker-compose up -d
		else
			echo "========== docker-compose donothing ========== " 
		fi
	fi
fi
