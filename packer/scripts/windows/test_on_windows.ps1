mkdir -Force C:\vagrant
cd C:\vagrant
git clone https://github.com/maxlinc/polytrix-openstack
cd polytrix-openstack
git checkout chocolatey
scripts/bootstrap.ps1
