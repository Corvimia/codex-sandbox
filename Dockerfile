FROM node:24-bookworm

# Base tools
RUN apt-get update
RUN apt-get install -y git ca-certificates zsh curl dnsutils gh openjdk-11-jdk

# Install codex
RUN npm i -g @openai/codex

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
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"
WORKDIR /workspace

ENTRYPOINT ["/bin/zsh"]
