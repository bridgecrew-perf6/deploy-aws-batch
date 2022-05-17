# FROM amazonlinux:latest
# RUN yum -y update
# RUN yum groupinstall -y 'Development Tools'
# RUN yum install -y which wget unzip aws-cli python3.7 git python3-pip cmake3 make devtoolset-10-gcc devtoolset-10-gcc-c++

# FROM continuumio/miniconda3
FROM python:3.7
# FROM ubuntu:20.04
ENV AWS_ACCESS_KEY_ID=AKIAZ3IT2NOOQEX3PPON
ENV AWS_SECRET_ACCESS_KEY=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
ENV AWS_DEFAULT_REGION=us-east-2
# ENV PATH /root/.local/bin:$PATH
ENV BASH_ENV /root/.bashrc
ENV MPLCONFIGDIR /tmp

ENV TZ=US
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update -y
RUN apt install -y tzdata

RUN apt-get install -y wget unzip awscli git cmake make gcc-10 g++-10 

ADD fetch_and_run.sh /usr/local/bin/fetch_and_run.sh
# RUN adduser -S nobody
# RUN mkdir /app && chown nobody: /app && cd /app
WORKDIR /app
RUN chown -R nobody: /app
RUN chmod 755 /app
ADD hypermapper_dev /app/hypermapper_dev
ADD taco /app/taco
RUN mkdir -p /app/taco/build
RUN cd /app/taco/build && cmake -DCMAKE_BUILD_TYPE=Release -DOPENMP=ON .. && make -j32 && cd -
ADD cpp_taco_SpMM.json /app/taco/build
COPY mtx_list.txt /app/mtx_list.txt
RUN pip install --no-cache-dir cython matplotlib jsonschema numpy scikit-optimize
RUN pip install /app/hypermapper_dev/.

# USER nobody
ENTRYPOINT ["/usr/local/bin/fetch_and_run.sh"]
