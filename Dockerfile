FROM centos:6 as centos-with-vsyscall
LABEL maintainer="Jean-Christophe BERGOT"

RUN sed -i '/mirrorlist/d' /etc/yum.repos.d/CentOS*.repo
# uncomment the base URL and change de URL subdomain from mirror to vault
RUN sed -i 's,#baseurl=http://mirror,baseurl=http://vault,g' /etc/yum.repos.d/*.repo
# Removing the centos in the URL path
RUN sed -i 's,/centos/,/,g;' /etc/yum.repos.d/*.repo
# and changing the releasever wich is and integer to the major.minor notation of the version
# But first geting it
RUN  myversion=$(cat /etc/redhat-release | awk '{print $3}') \
        && sed -i 's/$releasever/'${myversion}'/g' /etc/yum.repos.d/*.repo
# Get the GPG of the vault centos for deprecated OSes
RUN curl https://vault.centos.org/RPM-GPG-KEY-CentOS-6 --output RPM-GPG-KEY-CentOS-6
# Install it
RUN gpg --quiet --with-fingerprint ./RPM-GPG-KEY-CentOS-6

COPY ./files/yum/CentOS-source.repo /etc/yum.repos.d/

# Ok but need to try the script
RUN yum update -y
RUN yum install -y yum-utils rpm-build
RUN yum-builddep -y glibc
RUN adduser mockbuild
RUN mkdir /root/srpms 
RUN (cd /root/srpms && yumdownloader --source glibc)
RUN rpm -ivh /root/srpms/glibc-2.12-1.212.el6.src.rpm
RUN rpmbuild -bp /root/rpmbuild/SPECS/glibc.spec

COPY ./files/glibc/glibc.spec.patch /root/rpmbuild/SPECS/
COPY ./files/glibc/remove-vsyscall.patch /root/rpmbuild/SOURCES/

RUN cd /root/rpmbuild/SPECS/ && patch -p2 < glibc.spec.patch
RUN rpmbuild -ba /root/rpmbuild/SPECS/glibc.spec \
	&& mv /root/rpmbuild/RPMS/ /rpms



FROM centos:6
LABEL maintainer="Jean-Christophe BERGOT"

RUN sed -i '/mirrorlist/d' /etc/yum.repos.d/CentOS*.repo
# uncomment the base URL and change de URL subdomain from mirror to vault
RUN sed -i 's,#baseurl=http://mirror,baseurl=http://vault,g' /etc/yum.repos.d/*.repo
# Removing the centos in the URL path
RUN sed -i 's,/centos/,/,g;' /etc/yum.repos.d/*.repo
# and changing the releasever wich is and integer to the major.minor notation of the version
# But first geting it
RUN  myversion=$(cat /etc/redhat-release | awk '{print $3}') \
        && sed -i 's/$releasever/'${myversion}'/g' /etc/yum.repos.d/*.repo
# Get and install the GPG of the vault centos for deprecated OSes
RUN curl https://vault.centos.org/RPM-GPG-KEY-CentOS-6 --output /root/RPM-GPG-KEY-CentOS-6 \
	&& gpg --quiet --with-fingerprint /root/RPM-GPG-KEY-CentOS-6 \
	&& rm -f /root/RPM-GPG-KEY-CentOS-6 \
	&& mkdir /rpms

COPY --from=centos-with-vsyscall /rpms/x86_64/glibc-2.12-1.212.1.el6.x86_64.rpm /rpms 
COPY --from=centos-with-vsyscall /rpms/x86_64/glibc-common-2.12-1.212.1.el6.x86_64.rpm /rpms
RUN yum localinstall -y /rpms/* \ 
	&& rm -rf /rpms
	&& yum clean all

# TO Debug
CMD ["/bin/bash"]
#CMD ["/sbin/init"]
