FROM ubuntu AS docker-cli

RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends --yes --quiet \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
RUN mkdir -m 0755 -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends --yes --quiet docker-ce-cli

FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /natpmpc

RUN apt update
RUN apt install --no-install-suggests --no-install-recommends -y \ 
    iproute2 \
    vim \
    curl \
    natpmpc \
    bc \
    tzdata 

RUN ln -fs /usr/share/zoneinfo/Europe/Oslo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY --from=docker-cli /usr/bin/docker /usr/bin/docker

COPY --chmod=750 run.sh run.sh

CMD [ "./run.sh" ]

# ENTRYPOINT ["tail", "-f", "/dev/null"]