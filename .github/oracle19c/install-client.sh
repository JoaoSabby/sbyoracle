#!/usr/bin/env bash
set -euo pipefail

# Ubuntu 22.04 provides the libaio1 ABI required by the 19c client.
sudo apt-get update
sudo apt-get install --yes libaio1 unzip
client_root="${RUNNER_TEMP:?RUNNER_TEMP is required}/oracle-client"
mkdir -p "$client_root"
download_root="https://download.oracle.com/otn_software/linux/instantclient/1932000"
basic_file="instantclient-basic-linux.x64-19.32.0.0.0dbru.zip"
sdk_file="instantclient-sdk-linux.x64-19.32.0.0.0dbru.zip"
curl --fail --location --retry 3 "$download_root/$basic_file" --output "$client_root/$basic_file"
curl --fail --location --retry 3 "$download_root/$sdk_file" --output "$client_root/$sdk_file"

# Verify the official download checksums before extracting either archive.
(
  cd "$client_root"
  printf '%s  %s\n' \
    '1749ca1eb5f75b038f2b7ce0abc42eb4575928159259fc4fc851c54a8ca7b002' "$basic_file" \
    '1698b3be6dde8b7e90501a62122cb9c160c712eb709deb7129d915a504b76158' "$sdk_file" |
    sha256sum --check -
)
unzip -q -o "$client_root/$basic_file" -d "$client_root"
unzip -q -o "$client_root/$sdk_file" -d "$client_root"
client_dir="$client_root/instantclient_19_32"
test -f "$client_dir/libclntsh.so.19.1"
test -f "$client_dir/sdk/include/oci.h"

# Register libraries system-wide because R can replace LD_LIBRARY_PATH at startup.
printf '%s\n' "$client_dir" | sudo tee /etc/ld.so.conf.d/sbyoracle-ci.conf >/dev/null
sudo ldconfig
{
  echo "OCI_LIB=$client_dir"
  echo "OCI_INC=$client_dir/sdk/include"
  echo "LD_LIBRARY_PATH=$client_dir:${LD_LIBRARY_PATH:-}"
} >> "$GITHUB_ENV"
echo "$client_dir" >> "$GITHUB_PATH"
