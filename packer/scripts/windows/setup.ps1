iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

#  Setup Ruby
choco install git
choco install ruby
choco install ruby2.devkit

# DevKit doesn't always detect properly...
pushd C:\tools\DevKit2
#
[string]$RUBY_ROOT = ls C:\tools\ruby*
$ENTRY = $RUBY_ROOT.replace('\', '/')
"---`r`n- $ENTRY" | Out-File config.yml -Encoding utf8
ruby dk.rb install
popd

# Workaround https://github.com/rubygems/rubygems/issues/1050#issuecomment-61422934

$CERTIFICATE = "AddTrustExternalCARoot-2048.pem"
Invoke-WebRequest https://raw.githubusercontent.com/rubygems/rubygems/master/lib/rubygems/ssl_certs/$CERTIFICATE -OutFile $CERTIFICATE
$RUBY_HOME = gem which rubygems | Split-Path
Copy-Item $CERTIFICATE $RUBY_HOME/rubygems/ssl_certs

# Setup python

choco install python2
# This has trouble:
# choco install easy.install
# choco install pip

# So...
Invoke-WebRequest https://raw.github.com/pypa/pip/master/contrib/get-pip.py -OutFile get-pip.py
python get-pip.py
Write-Host $env:Path
$env:Path = $env:Path + ";C:\tools\python2\Scripts" # This should be added already....


pip install virtualenv
pip install virtualenvwrapper-win
