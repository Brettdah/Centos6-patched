# CentOS 6
## Important Notice
> /!\ CENTOS 6 reached it's END OF LIFE don't use that in prod it's for service continuity until migration

# How to use
This image is built on Docker Hub automatically any time the upstream OS container is rebuilt, and any time a commit is made or merged to the master branch. But if you need to build the image on your own locally, do the following:

1. Install [Docker](https://docs.docker.com/engine/installation/)
2. Clone this repository :
```bash
git clone https://github.com/Brettdah/Centos6-patched.git
```
3. Cd into the directory the default is : Centos6-patched.
4. Run docker
```bash
build -t <name the image> .
```

# A bit of context
## Why I did this image
I had trouble with the official Image of CentOS 6.10 going segfault when I tring to start it.  
I needed this to be able to test my ansible roles with molecule and docker on WSL2 Ubuntu 20.04

## A workaround ?
I first saw the official solution that was telling us to add this option to our kernel :
### On linux in /etc/default/grub
Find the kernel line and add :
```bash
... vsyscall=emulate
```
### For WSL in %userprofile%\.wslconfig
by default this file does not exist you may want to create it :
```powershell
Add-Content -Path $HOME\.wslconfig -Value "[wsl2]`r`vsyscall=emulate"
```
## The search of the root cause
It did not suit my philosophy so I investigate and found [this article](https://www.python.org/dev/peps/pep-0571/#compatibility-with-kernels-that-lack-vsyscall)  
So the root cause of my problem is the libC !  
OK, Let's [see what they have done](https://github.com/markrwilliams/manylinux/) with there build cause it works  
But there is many things I don't need, so let's dive in !

## Beeing up to date
at least having the last packages I can on my container...  
I based my work on their solutions and recompiled the glibc packages from this package that was the latest I could get from the [centos vault repo](https://vault.centos.org/) for centos 6.10 : glibc-2.12-1.212.el6.src.rpm  
And then apply their patch in this new version after a few changes to keep the official patch on the new version

# Release History
- latest => 1.0.1
- 1.0.0 => "Light" build, it point on the vault. the libc was fixed just updated glibc and glibc-common
- 1.0.1 => Add upstart so that I can finish with CMD["/sbin/init"] so the container stay up and running !

## To do
TBD : To Be Defined
