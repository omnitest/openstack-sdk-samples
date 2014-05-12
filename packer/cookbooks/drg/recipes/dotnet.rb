# FIXME: May need to setup a PPA to get a more recent Mono
# FIXME: Microsoft.Build.dll was not shipped with current Ubuntu stable Mono, is in latest.
# FIXME: Need to automate `mozroots --import --sync` before Mono can fetch packages.
include_recipe 'mono'
