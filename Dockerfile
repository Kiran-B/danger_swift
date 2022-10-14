FROM swift:5.7-focal

ARG SWIFTLINT_VERSION=0.50.0-rc.3

MAINTAINER Orta Therox

LABEL "com.github.actions.name"="Danger Swift"
LABEL "com.github.actions.description"="Runs Swift Dangerfiles"
LABEL "com.github.actions.icon"="zap"
LABEL "com.github.actions.color"="blue"

# Install nodejs and Danger
RUN apt-get update -q \
    && apt-get install -qy curl make ca-certificates \
    && curl -sL https://deb.nodesource.com/setup_14.x |  bash - \
    && apt-get install -qy nodejs \
    libcurl4-openssl-dev \
    libxml2-dev \
    && npm install -g danger \
    && rm -r /var/lib/apt/lists/*

ARG SWIFT_FLAGS="-c release -Xswiftc -static-stdlib -Xlinker -lCFURLSessionInterface -Xlinker -lCFXMLInterface -Xlinker -lcurl -Xlinker -lxml2 -Xswiftc -I. -Xlinker -fuse-ld=lld -Xlinker -L/usr/lib/swift/linux"

RUN git clone -b ${SWIFTLINT_VERSION} --single-branch --depth 1 https://github.com/realm/SwiftLint.git _swiftlint # swiftlint
RUN cd _swiftlint && git submodule update --init --recursive # swiftlint
RUN cd _swiftlint && ln -s /usr/lib/swift/_InternalSwiftSyntaxParser . && swift package update # swiftlint
RUN cd _swiftlint && swift build $SWIFT_FLAGS --product swiftlint # swiftlint
RUN cd _swiftlint && install -v `swift build $SWIFT_FLAGS --show-bin-path`/swiftlint /usr/local/bin # swiftlint
RUN rm -rf _swiftlint # swiftlint
RUN swiftlint version # swiftlint

# RUN git clone -b ${SWIFTLINT_VERSION} --single-branch --depth 1 https://github.com/realm/SwiftLint.git _swiftlint && cd _swiftlint && git submodule update --init --recursive && make build && rm -rf _swiftlint # old_swiftlint

# Install danger-swift globally
COPY . _danger-swift
RUN cd _danger-swift && make install && rm -rf _danger-swift

# Run Danger Swift via Danger JS, allowing for custom args
ENTRYPOINT ["danger-swift", "ci"]
