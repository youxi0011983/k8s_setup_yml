until "$@"; do
    sleep $(( (RANDOM % 11) + 5 ))  # 5-15秒随机延迟
done
