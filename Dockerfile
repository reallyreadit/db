# Simple Dockerfile based of the official Postgres image (which is based on Debian)
# Installs Powershell so we can run our database maintenance scripts.
# Should work for arm64 (M1 Macs) (tested), and for amd64 architectures (untested).

FROM postgres:14

# Install Powershell for the current architecture.
#
# We need to use the binary archive installation method to support both aarch64 and amd64
# See https://docs.microsoft.com/en-us/powershell/scripting/install/install-other-linux?view=powershell-7.2#binary-archives
RUN apt update && apt install -y curl \
	&& curl -L -o /tmp/powershell.tar.gz \
	# About the $() substitution here: we want to download the right -x64.tar.gx or -arm64.tar.gz. But inside Debian, runnin arch returns aarch64.
		https://github.com/PowerShell/PowerShell/releases/download/v7.2.3/powershell-7.2.3-linux-$([ "$(arch)" = "aarch64" ] && echo "arm64" || echo "x64").tar.gz \
	# Create the target folder where powershell will be placed
	&& mkdir -p /opt/microsoft/powershell/7 \
	# Expand powershell to the target folder
	&& tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
	# Set execute permissions
	&& chmod +x /opt/microsoft/powershell/7/pwsh \
	# Create the symbolic link that points to pwsh
	&& ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh