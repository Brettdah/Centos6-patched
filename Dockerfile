FROM centos:6 as centos-with-vsyscall
LABEL maintainer="Jean-Christophe BERGOT"

COPY ./files/yum/CentOS-source.repo /etc/yum.repos.d/

RUN myversion=$(cat /etc/redhat-release | awk '{print $3}') \
	&& sed -i '/mirrorlist/d;s,#baseurl=http://mirror,baseurl=http://vault,g;s,/centos/,/,g;s/$releasever/'${myversion}'/g' /etc/yum.repos.d/*.repo \
	&& curl https://vault.centos.org/RPM-GPG-KEY-CentOS-6 --output /root/RPM-GPG-KEY-CentOS-6 \
	&& gpg --quiet --with-fingerprint /root/RPM-GPG-KEY-CentOS-6 \
	&& rm -rf /root/RPM-GPG-KEY-CentOS-6 \
	&& yum update -y \
	&& yum install -y yum-utils rpm-build \
	&& yum-builddep -y glibc \
	&& adduser mockbuild \
	&& mkdir /root/srpms \
	&& (cd /root/srpms && yumdownloader --source glibc) \
	&& rpm -ivh /root/srpms/glibc-2.12-1.212.el6.src.rpm \
	&& rpmbuild -bp /root/rpmbuild/SPECS/glibc.spec

COPY ./files/glibc/glibc.spec.patch /root/rpmbuild/SPECS/
COPY ./files/glibc/remove-vsyscall.patch /root/rpmbuild/SOURCES/

RUN cd /root/rpmbuild/SPECS/ && patch -p2 < glibc.spec.patch \
	&& rpmbuild -ba /root/rpmbuild/SPECS/glibc.spec \
	&& mv /root/rpmbuild/RPMS/ /rpms

###################
### END BUILDER ###
###################

FROM centos:6
LABEL maintainer="Jean-Christophe BERGOT"

RUN myversion=$(cat /etc/redhat-release | awk '{print $3}') \
        && sed -i '/mirrorlist/d;s,#baseurl=http://mirror,baseurl=http://vault,g;s,/centos/,/,g;s/$releasever/'${myversion}'/g' /etc/yum.repos.d/*.repo \
        && curl https://vault.centos.org/RPM-GPG-KEY-CentOS-6 --output /root/RPM-GPG-KEY-CentOS-6 \
        && gpg --quiet --with-fingerprint /root/RPM-GPG-KEY-CentOS-6 \
        && rm -rf /root/RPM-GPG-KEY-CentOS-6

COPY --from=centos-with-vsyscall /rpms/x86_64/glibc-2.12-1.212.1.el6.x86_64.rpm /rpms 
COPY --from=centos-with-vsyscall /rpms/x86_64/glibc-common-2.12-1.212.1.el6.x86_64.rpm /rpms
RUN yum localinstall -y /rpms/* \
	&& rm -rf /rpms \
	&& yum clean all

# TO Debug
CMD ["/bin/bash"]
#CMD ["/sbin/init"]
