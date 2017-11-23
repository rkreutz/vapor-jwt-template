FROM ubuntu

# Install CURL
RUN apt-get update && \
    apt-get -y install curl && \
    rm -rf /var/lib/apt/lists/*;

# Get Vapor repo including Swift
RUN curl -sL https://apt.vapor.sh | bash;

# Installing Swift & Vapor
RUN apt-get update && \
    apt-get -y install swift vapor && \
    rm -rf /var/lib/apt/lists/*;

VOLUME ["/vapor"]
WORKDIR /vapor

ENV PORT 8080
EXPOSE 8080

ENV DATABASE_URL mongodb://mongo:27017/teste

CMD vapor build | vapor run --env=production
