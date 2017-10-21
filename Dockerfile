FROM rocker/tidyverse
MAINTAINER Fabien Rinaldi
USER root

# install cron and R package dependencies
RUN apt-get update && apt-get install -y \
cron \
nano \
## clean up
&& apt-get clean \ 
&& rm -rf /var/lib/apt/lists/ \ 
&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN apt-get update \
    && apt-get install -y python-pip build-essential \
    && apt-get -y autoremove \
    && apt-get -y clean  \
    && rm -rf /var/lib/apt/lists/*

# Pip install python
RUN pip install pip -U \
    && pip install -r /requirements.txt \
    && pip install jupyter_contrib_nbextensions \
    && rm -r /root/.cache/pip
    
RUN jupyter contrib nbextension install

COPY notebook.json /root/.jupyter/nbconfig/notebook.json

CMD jupyter-notebook --ip="*" --no-browser     

RUN mkdir /var/run/sshd
RUN echo 'root:root123' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

## Install packages from CRAN
RUN install2.r --error \ 
-r 'http://cran.rstudio.com' \
googleAuthR shinyFiles googleCloudStorageR bigQueryR gmailr googleAnalyticsR \
## install Github packages
&& Rscript -e "devtools::install_github(c('bnosac/cronR'))" \
## clean up
&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \

## Start cron
RUN sudo service cron start