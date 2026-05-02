#!/bin/bash
# یک حلقه‌ی بی‌نهایت برای ارسال و دریافت
while true; do
  # فرض می‌کنیم که فایل request.txt شامل درخواست خام است
  if [ -f request.txt ]; then
    cp request.txt outgoing.txt
    rm request.txt
    git add outgoing.txt
    git commit -m "TURTLE_REQUEST" && git push
    
    # منتظر دریافت پاسخ می‌مانیم
    while [ ! -f incoming.txt ]; do
      git pull --rebase origin master
      sleep 2
    done
    cat incoming.txt
    rm incoming.txt
  fi
  sleep 1
done
