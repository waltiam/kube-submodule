# Note: You can use any Debian/Ubuntu based image you want. 
FROM mcr.microsoft.com/vscode/devcontainers/base:0-buster

# Options
ARG INSTALL_ZSH="true"
ARG UPGRADE_PACKAGES="false"
ARG USE_MOBY="true"
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && /bin/bash /tmp/library-scripts/docker-in-docker-debian.sh "true" "${USERNAME}" "${USE_MOBY}" \ 
    && /bin/bash /tmp/library-scripts/kubectl-helm-debian.sh "latest" "latest" "latest" \
    && mkdir -p /home/${USERNAME}/.minikube \
    && chown ${USERNAME} /home/${USERNAME}/.minikube \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

VOLUME [ "/var/lib/docker" ]

# Setting the ENTRYPOINT to docker-init.sh will start up the Docker Engine 
# inside the container "overrideCommand": false is set in devcontainer.json. 
# The script will also execute CMD if you need to alter startup behaviors.
ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]*

# My stuff

# Configure bash
# COPY library-scripts/update-bash.sh \
#     /tmp/library-scripts/
# RUN bash /tmp/library-scripts/update-bash.sh "${USERNAME}" \
#     && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

# Install NeoVim 
# ARG INSTALL_NEOVIM="true"
COPY custom-scripts/init.vim \
    custom-scripts/install-neovim.sh \
    /tmp/library-scripts/
RUN bash /tmp/library-scripts/install-neovim.sh "${USERNAME}" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Install Chrome (headless)
# RUN /bin/bash /tmp/library-scripts/install-chrome.sh:w

# Install and configure zsh
COPY custom-scripts/update-zsh.sh \
    custom-scripts/.p10k.zsh \
    custom-scripts/.zshrc \
    /tmp/library-scripts/
RUN /bin/bash /tmp/library-scripts/update-zsh.sh "${USERNAME}" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Configure GIT ...
COPY custom-scripts/configure-git.sh /tmp/library-scripts/
RUN /bin/bash /tmp/library-scripts/configure-git.sh "${USERNAME}" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Configure SSH ... 
COPY custom-scripts/configure-sign.sh /tmp/library-scripts/
RUN /bin/bash /tmp/library-scripts/configure-sign.sh "${USERNAME}" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Configure commit signing
COPY certs/* /tmp/certs/ 
RUN /bin/bash /tmp/certs/configure-cert.sh \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# install kustomize
COPY custom-scripts/install-kustomize.sh /tmp/library-scripts/
RUN /bin/bash /tmp/library-scripts/install-kustomize.sh \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment the next line to use go get to install anything else you need
# RUN go get -x <your-dependency-or-tool>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# Remove library scripts for final image
# RUN apt-get clean -y \
#     && rm -rf /tmp/library-scripts \
#     && rm -rf /var/lib/apt/lists/*