
FROM debian:latest
# Minecraft
ENV C_USER cuberite
ENV C_WORLDS_DIR /var/lib/minecraft
ENV C_HOME /home/$C_USER

# set user/group IDs
RUN groupadd -r "$C_USER" --gid=999 && useradd -r -g "$C_USER" --uid=999 "$C_USER"


# Base
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
	&& apt-get install --no-install-recommends --yes \
		ca-certificates curl nano gcc g++ make cmake git\
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/

# Gosu
RUN curl -o /usr/local/sbin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
	&& chmod +x /usr/local/sbin/gosu

# Preparing cuberite
RUN mkdir -p $C_WORLDS_DIR && chown -R $C_USER:$C_USER $C_WORLDS_DIR


# Cuberite
RUN mkdir "$C_HOME" \
	&& cd "$C_HOME" \
	&& git clone https://github.com/cuberite/cuberite.git \
  && cd cuberite \
  && git submodule update --init \
  && pwd

RUN pwd
# Build
RUN  cd "$C_HOME" && cd cuberite && mkdir build-cuberite && cd build-cuberite \
  && cmake .. -DCMAKE_BUILD_TYPE=Release \
  && make -j`nproc` \
  && cd ../Server

RUN mv "$C_HOME"/cuberite/Server "$C_HOME"/Server

COPY configs/ "$C_HOME"/Server
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25565 8080

# Creating volume
VOLUME $C_HOME
VOLUME $C_WORLDS_DIR

WORKDIR $C_HOME

CMD ["./start_cuberite.sh"]
