%global crate dcli

Name:           dcli
Version:        0.2.2
Release:        1%{?dist}
Summary:        A declarative package management CLI tool for Linux

License:        0BSD
URL:            https://gitlab.com/theblackdon/dcli
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  make

# mlua vendors lua54 (no external lua-devel needed)

%description
dcli is a declarative package management CLI tool for Linux, inspired by NixOS.
It allows you to declare your system configuration and packages in YAML files
and sync your system to match that configuration.

%prep
%autosetup

# Set up cargo config for vendored dependencies and linker flags
mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"

[target.x86_64-unknown-linux-gnu]
rustflags = ["-C", "link-arg=-fuse-ld=bfd"]
EOF

%build
cargo build --release --locked

%install
# Install the binary
install -Dpm 0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

# Install zsh completion
install -Dpm 0644 _dcli %{buildroot}%{_datadir}/zsh/site-functions/_dcli

%files
%license LICENSE
%doc README.md docs/
%{_bindir}/%{name}
%{_datadir}/zsh/site-functions/_dcli

%changelog
* Wed Jul 01 2026 Don <theblackdonatello@gmail.com> - 0.2.2-1
- Update to 0.2.2
* Wed Jul 01 2026 Don <theblackdonatello@gmail.com> - 0.2.1-1
- Update to 0.2.1
* Tue Jul 01 2025 Don <theblackdonatello@gmail.com> - 0.2.0-1
- Initial COPR package
