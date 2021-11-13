read -p "do you want to wipe full drive, or press enter to use defaults: " part
if [[ -z $part ]]; then
    part=yes
fi

if $part=no; then
  echo success
else
echo failure
fi
