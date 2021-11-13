read -p "do you want to wipe full drive, or press enter to use defaults: " part
if [[ -z $part ]]; then
    part=yes
fi

if $part=no; then
  echo success
else
echo failure
fi
if ping -q -c 1 -W 1 2001:4860:4860::8888 >/dev/null; then
  ipv=ipv6
else
  if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  ipv=ipv4
else
  echo "not online" 
fi
fi
