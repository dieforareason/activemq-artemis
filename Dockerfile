FROM i.asyx.com:4999/asyx/java-11
MAINTAINER "Aji Fauzan <aji.fauzan@asyx.com>"

USER root
RUN useradd -ms /bin/bash asyx -p asyx
ENV ACTIVEMQ_ARTEMIS_VERSION 2.6.2
ENV ARTEMIS_HOME /opt/apache-artemis-${ACTIVEMQ_ARTEMIS_VERSION}
ENV BROKERS_HOME /var/lib/broker
ENV BROKER_NAME xchange4
ENV ARTEMIS_USER aji
ENV ARTEMIS_PASSWORD aji123


RUN  yum -y install epel-release && \
     yum -y install wget curl xmlstarlet \
     && yum -y clean all \
     && rm -rf /var/cache/yum \
     && cd /opt \
     && wget -q https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-artemis/${ACTIVEMQ_ARTEMIS_VERSION}/apache-artemis-${ACTIVEMQ_ARTEMIS_VERSION}-bin.tar.gz && \
     wget -q https://repository.apache.org/content/repositories/releases/org/apache/activemq/apache-artemis/${ACTIVEMQ_ARTEMIS_VERSION}/apache-artemis-${ACTIVEMQ_ARTEMIS_VERSION}-bin.tar.gz.asc && \
     wget -q http://apache.org/dist/activemq/KEYS && \
     gpg --import KEYS && \
     gpg apache-artemis-${ACTIVEMQ_ARTEMIS_VERSION}-bin.tar.gz.asc && \
     tar xfz apache-artemis-${ACTIVEMQ_ARTEMIS_VERSION}-bin.tar.gz && \
     mkdir -p /var/lib/broker &&  \
     ${ARTEMIS_HOME}/bin/artemis create ${BROKERS_HOME}/${BROKER_NAME} \
       --home ${ARTEMIS_HOME} \
       --user ${ARTEMIS_USER} \       
       --password ${ARTEMIS_PASSWORD} \
       --allow-anonymous

COPY run-broker.sh container-limits java-default-options ${BROKERS_HOME}/

ADD ./extras/jolokia-access.xml ${BROKERS_HOME}/${BROKER_NAME}/etc/jolokia-access.xml

RUN chmod 755 ${BROKERS_HOME}/run-broker.sh  ${BROKERS_HOME}/java-default-options ${BROKERS_HOME}/container-limits \
    && chown -R asyx ${BROKERS_HOME} \
    && usermod -g root -G `id -g asyx` asyx \
    && chmod -R "g+rwX" ${BROKERS_HOME} \
    && chown -R asyx:root ${BROKERS_HOME} \
    && cd ${BROKERS_HOME}/${BROKER_NAME}/etc && \
    xmlstarlet ed -L -N amq="http://activemq.org/schema" \
    -u "/amq:broker/amq:web/@bind" \
    -v "http://0.0.0.0:8161" bootstrap.xml


EXPOSE 8161 61616 5445 5672 1883 61613

#TODO volumes
VOLUME ["${BROKERS_HOME}"]
WORKDIR ${BROKERS_HOME}
USER asyx

CMD [ "/bin/sh","-c", "${BROKERS_HOME}/run-broker.sh" ]