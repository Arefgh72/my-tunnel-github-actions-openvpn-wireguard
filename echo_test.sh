#!/bin/bash
echo "Enter message:"
read MSG
echo "$MSG" > echo_request.txt
git add echo_request.txt
git commit -m "ECHO_REQUEST" && git push

echo "Waiting for response..."
while [ ! -f echo_response.txt ]; do
  git pull --rebase origin master
  sleep 2
done
echo "Response: $(cat echo_response.txt)"
rm echo_response.txt
