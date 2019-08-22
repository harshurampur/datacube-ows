FROM opendatacube/datacube-core:1.7

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3-matplotlib \
    python3-pil\
    libpng-dev \
    wget \
    vim \
    unzip \
    postgresql-client \
    jq \
    awscli \
    curl \
    libev-dev \
    && rm -rf /var/lib/apt/lists/*

# Perform setup install
RUN mkdir -p /code/setup
WORKDIR /code/setup

ADD . .

# On Ubuntu 18.04 default pip version is awfully old and does not support --extra-index-url command line option,
# so make sure to upgrade pip first: pip3 install --upgrade pip.
RUN pip3 install --upgrade pip \
    && rm -rf $HOME/.cache/pip

RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/requirements.txt

RUN pip3 install -r requirements.txt \
    && rm -rf $HOME/.cache/pip

# ODC cloud tools depend on aiobotocore which has a dependency on a specific version of botocore,
# boto3 also depends on a specific version of botocore as a result having both aiobotocore and boto3 in one
# environment can be a bit tricky. The easiest way to solve this is to install aiobotocore[awscli,boto3] before
# anything else, which will pull in a compatible version of boto3 and awscli into the environment.
RUN pip3 install -U 'aiobotocore[awscli,boto3]' \
    && rm -rf $HOME/.cache/pip

RUN pip3 install --extra-index-url="https://packages.dea.gadevs.ga" \
    odc-apps-cloud \
    odc-apps-dc-tools \
    && rm -rf $HOME/.cache/pip

RUN pip3 install . \
    && rm -rf $HOME/.cache/pip

RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/setup-k/assets/create-db.sh
RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/setup-k/assets/drop-db.sh

# Install dea proto for indexing tools
RUN mkdir -p /code/index/indexing
WORKDIR /code/index/indexing

RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/index-k/assets/update_ranges.sh
RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/index-k/assets/update_ranges_wrapper.sh
ADD https://raw.githubusercontent.com/opendatacube/datacube-dataset-config/master/scripts/index_from_s3_bucket.py \
    ls_s2_cog.py

WORKDIR /code/index
RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/index-k/assets/create-index.sh

# Archive install
RUN mkdir -p /code/archive/archiving
WORKDIR /code/archive

RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/archive/assets/archive-wrapper.sh

WORKDIR /code/archive/archiving
RUN wget https://raw.githubusercontent.com/opendatacube/datacube-ows/master/docker/auxiliary/archive/assets/archive.sh
ADD https://raw.githubusercontent.com/opendatacube/datacube-dataset-config/master/scripts/index_from_s3_bucket.py \
    ls_s2_cog.py

WORKDIR /code
