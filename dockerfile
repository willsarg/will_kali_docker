FROM kalilinux/kali-last-release:amd64

# Use bash shell with pipefail for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Update and install minimal core
# hadolint ignore=DL3002,DL3015,DL3008,DL3009
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    tightvncserver \
    openssh-server \
    sudo \
    dbus-x11

# Step 2: Install large meta-package (can be cached separately)
# hadolint ignore=DL3015,DL3008
RUN apt-get update && apt-get install -y kali-linux-headless \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up user "will" and configure SSH root login and SSH directory
RUN useradd -m -s /bin/bash will \
    && echo "will:will" | chpasswd \
    && adduser will sudo \
    && sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && mkdir -p /var/run/sshd

# Configure VNC
USER will
RUN mkdir -p /home/will/.vnc && \
    echo "will" | vncpasswd -f > /home/will/.vnc/passwd && \
    chmod 600 /home/will/.vnc/passwd

USER root
COPY xstartup /home/will/.vnc/xstartup
RUN chmod +x /home/will/.vnc/xstartup

# hadolint ignore=DL3002
USER root

# Expose ports
EXPOSE 22 5901

# Startup script
CMD ["/bin/bash", "-c", "service ssh start && runuser -l will -c 'vncserver :1 -geometry 1920x1080 -depth 24' && tail -f /dev/null"]