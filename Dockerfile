FROM ubuntu:14.04 
MAINTAINER LouisBiancherin
ENV HOME /home/MODIS
EXPOSE 22
USER root

ARG MRT_DATA_DIR=/home/MODIS/MRT/data


RUN apt-get update                                                          \
        && apt-get -y install apt-transport-https                           \
        && apt-get -y upgrade                                               

RUN apt-get install -y build-essential                                      \
	    && apt-get install -y software-properties-common                    \
	    && apt-get install -y byobu curl git htop man vim nano wget unzip   \
	    && apt-get install -y default-jdk                                   \
        && apt-get install -y r-base                                        \
        && apt-get install -y python-pip  openssh-server         

RUN  echo "search atlas.edf.fr" > /etc/resolv.conf  && \
     echo "nameserver 10.203.40.12" >> /etc/resolv.conf && \
     echo "nameserver 10.203.0.142" >> /etc/resolv.conf          

RUN pip install bs4                   \
		&& rm -rf /var/lib/apt/lists/ 

RUN useradd MODIS --uid 1039 --create-home  && \
    usermod -aG sudo MODIS

RUN mkdir /var/run/sshd
RUN echo 'MODIS:modis123' | chpasswd
RUN echo 'root:root123' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

COPY netcdf-c-4.4.1.1.tar.gz /home/MODIS
COPY mrt_install_am /home/MODIS
COPY MRT_download_Linux64.zip /home/MODIS
COPY gdal213.zip /home/MODIS
#ADD https://repo.continuum.io/archive/Anaconda3-4.3.0-Linux-x86_64.sh /home/MODIS
COPY nco_4.6.3.orig.tar.gz /home/MODIS
#ADD https://launchpad.net/ubuntu/+archive/primary/+files/nco_4.6.3.orig.tar.gz /home/MODIS

WORKDIR /home/MODIS

RUN mkdir MRT/                                                              \
	    && unzip MRT_download_Linux64.zip                                   \
	    && bash mrt_install_am

# adding PPA repo
# RUN add-apt-repository ppa:ubuntugis/ubuntugis-unstable          
RUN echo "deb http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu trusty main" > /etc/apt/sources.list.d/ubuntugis-ppa-trusty.list

###########install netcdf and glad######################    
RUN apt-get -y update                                                       \
        && apt-get --allow-unauthenticated install -y libgdal20             \
        && tar xzvf netcdf-c-4.4.1.1.tar.gz                                 \
        && cd netcdf-4.4.1.1                                                \
        && ./configure --prefix=/usr/local/netcdf --disable-netcdf-4        \
        && make                                                             \
        && make install                                                     \
        && cd /home/MODIS/                                                  \
        && unzip gdal213.zip                                                \
        && cd gdal-2.1.3/                                                   \
        && ./configure --with-netcdf=/usr/local/netcdf                      \
        && make -j 10                                                       \
        && make install                                                     

#####install NCO######
RUN  tar zxvf nco_4.6.3.orig.tar.gz                                         \
        && apt-get install -y antlr libantlr-dev                            \
        && apt-get install -y libcurl4-gnutls-dev libexpat1-dev libxml2-dev \
	    && apt-get install -y libnetcdfc7 libnetcdf-dev netcdf-bin          \
        && apt-get install -y bison flex gcc g++                            \
        && apt-get install -y gsl-bin libgsl0-dev                           \
        && cd nco-4.6.3                                                     \
        && ./configure                                                      \
        && make install 

# Add crontab
ADD modis-crontab /etc/cron.d/modis-crontab
RUN chmod 0644 /etc/cron.d/modis-crontab

RUN touch /var/log/cron.log

CMD cron && /usr/sbin/sshd -D && tail -f /var/log/cron.log
