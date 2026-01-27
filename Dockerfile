FROM node:24-bookworm

# Base tools
RUN apt-get update
RUN apt-get install -y git ca-certificates zsh curl dnsutils gh

# Install toolset (managed via volumes/tools)
WORKDIR /opt/tools
COPY volumes/tools/package.json volumes/tools/pnpm-lock.yaml ./
RUN corepack enable
RUN corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile

# Non-root user
RUN useradd -m -s /bin/zsh sandbox
RUN mkdir -p /workspace
RUN chown -R sandbox:sandbox /workspace
RUN touch /home/sandbox/.zshrc
RUN chown sandbox:sandbox /home/sandbox/.zshrc
RUN mkdir -p /home/sandbox/.ssh
RUN chmod 700 /home/sandbox/.ssh \
  && chown -R sandbox:sandbox /home/sandbox/.ssh

USER sandbox

ENV HOME=/home/sandbox
ENV PATH="/opt/tools/node_modules/.bin:${PATH}"
WORKDIR /workspace

ENTRYPOINT ["/bin/zsh"]
