docker run -d \
  --name code-server \
  -p 8080:8080 \
  -v "$HOME/.config:/home/coder/.config" \
  -v "$PWD:/home/coder/project" \
  codercom/code-server:latest