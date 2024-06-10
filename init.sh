#!/bin/bash
### BEGIN INIT INFO
# Provides:          mygpu-monitor
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: GPU Monitoring Service
# Description:       Monitors GPU activity and stops pod if idle for too long
### END INIT INFO

# Change these variables according to your environment
ENVFILE="/etc/environment.env"
SCRIPT="/pibbss-infra/daemon.sh"

# Include the init functions library
. /lib/lsb/init-functions

# Check if the environment file exists
if [ ! -f "$ENVFILE" ]; then
    log_failure_msg "Environment file $ENVFILE not found"
    exit 1
fi

# Check if the script exists
if [ ! -f "$SCRIPT" ]; then
    log_failure_msg "Script $SCRIPT not found"
    exit 1
fi

# Set permissions for the script
chmod +x "$SCRIPT"

case "$1" in
    start)
        log_daemon_msg "Starting mygpu-monitor service"
        start-stop-daemon --start --background --make-pidfile --pidfile /var/run/mygpu-monitor.pid --exec "$SCRIPT"
        ;;
    stop)
        log_daemon_msg "Stopping mygpu-monitor service"
        start-stop-daemon --stop --pidfile /var/run/mygpu-monitor.pid
        ;;
    restart)
        log_daemon_msg "Restarting mygpu-monitor service"
        $0 stop
        sleep 1
        $0 start
        ;;
    status)
        status_of_proc -p /var/run/mygpu-monitor.pid "$SCRIPT" mygpu-monitor && exit 0 || exit $?
        ;;
    *)
        log_failure_msg "Usage: $SCRIPT {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
