xDir="/home/pi/OSPath/pi"

echo xDir		= $xDir
echo "param 0:"$0
echo "param 1:"$1
echo "param 2:"$2
echo "param 3:"$3
echo "param 4:"$4
echo "param 5:"$5

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

