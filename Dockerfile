FROM node:24-bookworm

# Base tools
RUN apt-get update
RUN apt-get install -y git ca-certificates zsh curl dnsutils gh

# Install codex
RUN npm i -g @openai/codex
RUN npm i -g pnpm

# Non-root user
RUN useradd -m -s /bin/zsh sandbox
RUN mkdir -p /workspace
RUN chown -R sandbox:sandbox /workspace
RUN touch /home/sandbox/.zshrc
RUN chown sandbox:sandbox /home/sandbox/.zshrc
COPY volumes/gitconfig/.gitconfig /home/sandbox/.gitconfig
RUN chown sandbox:sandbox /home/sandbox/.gitconfig

USER sandbox

ENV HOME=/home/sandbox
WORKDIR /workspace

ENTRYPOINT ["/bin/zsh"]
