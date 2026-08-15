# shellcheck disable=SC2148
PATH=/usr/bin:/usr/sbin

get_opt() {
  echo "$@" | cut -d "=" -f 2
}

firstboot=0

# shellcheck disable=SC2013
# shellcheck disable=SC1001
for i in $(cat /proc/cmdline); do
  case $i in
    thing.firstboot\=*)
      firstboot=$(get_opt "$i")
      ;;
  esac
done

if [ "${firstboot}" -eq 1 ]; then
  /sbin/reset-data
  /sbin/reset-settings
  if ! /usr/bin/uenv set firstboot 0; then
    sleep 1
    /usr/bin/uenv set firstboot 0 \
      || echo "firstboot: FAILED to clear firstboot flag; data will be wiped again next boot!" >&2
  fi
  
  # Generate SSH host keys on first boot if they don't exist
  if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" -q
  fi
  if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" -q
  fi
fi
