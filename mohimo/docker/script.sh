attempt=1
until "$@"; do
    delay=$(( (RANDOM % 10) + 1 ))
    echo "Attempt $attempt failed. Retrying in ${delay}s..."
    sleep $delay
    ((attempt++))
done
echo "Succeeded after $attempt attempts"
