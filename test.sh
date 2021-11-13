read -p "do you want to wipe full drive, or press enter to use defaults: " part
if [[ -z $part ]]; then
    part=yes
fi

if $part=no; then
echo 1
echo 2
echo 3
else
echo 5
echo 7
echo 8
fi
