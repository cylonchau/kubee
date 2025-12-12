Name: kubee
Version: %{_version}
Release: 1%{?dist}
Summary: Lightweight Kubernetes toolkit for secure kubeconfig management and aliases
License: MIT
Source0: kubee.sh
Source1: kubee-aliases.sh

BuildRequires: shc, gcc
Requires: bash, openssl

%description
Kubee is a lightweight toolkit for managing Kubernetes kubeconfig files securely with encryption
and providing convenient aliases for kubectl commands.

%build
# Compile kubee.sh to binary using shc
shc -f %{SOURCE0} -o kubee -r

%install
# Install binary
install -D -m 755 kubee %{buildroot}/usr/sbin/kubee
# Install aliases
install -D -m 644 %{SOURCE1} %{buildroot}/etc/profile.d/kubee-aliases.sh
# Install config file
echo -e 'KUBE_PASS="vz8g97YaKgf8=ui_t^En"\nUSE_PASSWORD=false' > %{buildroot}/etc/.kubee

%post
# Ensure aliases are loaded in new sessions
echo "source /etc/profile.d/kubee-aliases.sh" > /dev/null

%preun
# No action needed before uninstall
:

%postun
# Clean up aliases and config on uninstall
if [ $1 -eq 0 ]; then
  rm -f /etc/profile.d/kubee-aliases.sh
  rm -f /etc/.kubee
fi

%files
%attr(0755,root,root) /usr/sbin/kubee
%attr(0755,root,root) /etc/profile.d/kubee-aliases.sh
%attr(0600,root,root) /etc/.kubee

%changelog
* Thu Jul 24 2025 cylon <cylonchau@outlook.com> - 1.0.0-2
- Initial release