# Use Debian base image
FROM debian:bullseye

# Install necessary packages and Guacamole server components
RUN apt-get update && apt-get install -y \
    openssh-server tightvncserver xrdp guacamole guacd guacamole-tomcat \
    libsqlite3-dev sqlite3 sudo love

# Install Guacamole extensions and configure SQLite (omit this part for in-memory)
RUN mkdir -p /etc/guacamole/extensions /etc/guacamole/lib && \
    cp /usr/share/guacamole/extensions/guacamole-auth-jdbc-sqlite-*.jar /etc/guacamole/extensions/

# Configure Guacamole to use in-memory SQLite
RUN echo "[database]" > /etc/guacamole/guacamole.properties && \
    echo "driver=sqlite" >> /etc/guacamole/guacamole.properties && \
    echo "database=:memory:" >> /etc/guacamole/guacamole.properties

# Expose ports for SSH and VNC
EXPOSE 22 5900

# Create two users: 'admin' for SSH access, 'player' for VNC-only access
ARG ADMIN_USERNAME=admin
ARG PLAYER_USERNAME=player

RUN useradd -m ${ADMIN_USERNAME} && echo "${ADMIN_USERNAME}:${ADMIN_USERNAME}" | chpasswd && adduser ${ADMIN_USERNAME} sudo && \
    useradd -m ${PLAYER_USERNAME} && echo "${PLAYER_USERNAME}:${PLAYER_USERNAME}" | chpasswd

# Configure SSH for 'admin' only, restrict 'player' from SSH
RUN echo "AllowUsers ${ADMIN_USERNAME}" >> /etc/ssh/sshd_config && \
    echo "DenyUsers ${PLAYER_USERNAME}" >> /etc/ssh/sshd_config

# Configure VNC server for 'player' only
USER ${PLAYER_USERNAME}
RUN mkdir -p /home/${PLAYER_USERNAME}/.vnc && \
    echo "${PLAYER_USERNAME}vnc" | vncpasswd -f > /home/${PLAYER_USERNAME}/.vnc/passwd && \
    chmod 600 /home/${PLAYER_USERNAME}/.vnc/passwd

# Create shared modules directory and copy shared Lua modules
USER root
RUN mkdir -p /shared_modules
COPY shared_modules /shared_modules
RUN chown -R ${ADMIN_USERNAME}:${ADMIN_USERNAME} /shared_modules && \
    chown -R ${PLAYER_USERNAME}:${PLAYER_USERNAME} /shared_modules

# Copy Love2D server and client code into the container
COPY love2d-server.lua /home/${ADMIN_USERNAME}/love2d-server.lua
COPY love2d-client.lua /home/${PLAYER_USERNAME}/love2d-client.lua

# Set proper permissions
RUN chown ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/love2d-server.lua && \
    chown ${PLAYER_USERNAME}:${PLAYER_USERNAME} /home/${PLAYER_USERNAME}/love2d-client.lua && \
    chmod 700 /home/${ADMIN_USERNAME}/love2d-server.lua && \
    chmod 700 /home/${PLAYER_USERNAME}/love2d-client.lua

# Make shared modules accessible to both users
RUN ln -s /shared_modules /home/${PLAYER_USERNAME}/shared_modules && \
    ln -s /shared_modules /home/${ADMIN_USERNAME}/shared_modules && \
    chown -h ${PLAYER_USERNAME}:${PLAYER_USERNAME} /home/${PLAYER_USERNAME}/shared_modules && \
    chown -h ${ADMIN_USERNAME}:${ADMIN_USERNAME} /home/${ADMIN_USERNAME}/shared_modules

# Ensure 'player' can only access client and not server or parent container code
RUN chmod 700 /home/${ADMIN_USERNAME} && chmod 750 /home/${PLAYER_USERNAME}

# Switch back to root to run services
USER root

# Set entrypoint to start SSH, VNC servers, and Love2D
CMD ["/bin/bash", "-c", "service ssh start && service xrdp start && guacd -b 0.0.0.0 -f && sudo -u ${PLAYER_USERNAME} love /home/${PLAYER_USERNAME}/love2d-client.lua & sudo -u ${ADMIN_USERNAME} love /home/${ADMIN_USERNAME}/love2d-server.lua"]
