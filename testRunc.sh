sudo setenforce 0

make clean && make
cd container

sudo mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

export PATH="${PATH}:/system/xbin:/system/bin"
opts='rw,nosuid,nodev,noexec,relatime'
cgroups='blkio cpu cpuacct cpuset devices freezer memory pids schedtune'

# try to mount cgroup root dir and exit in case of failure
if ! sudo mountpoint -q /sys/fs/cgroup 2>/dev/null; then
  sudo mkdir -p /sys/fs/cgroup
  sudo mount -t tmpfs -o "${opts}" cgroup_root /sys/fs/cgroup || exit
fi

# try to mount cgroup2
if ! sudo mountpoint -q /sys/fs/cgroup/cg2_bpf 2>/dev/null; then
  sudo mkdir -p /sys/fs/cgroup/cg2_bpf
  sudo mount -t cgroup2 -o "${opts}" cgroup2_root /sys/fs/cgroup/cg2_bpf
fi

# try to mount differents cgroups
for cg in ${cgroups}; do
  if ! sudo mountpoint -q "/sys/fs/cgroup/${cg}" 2>/dev/null; then
    sudo mkdir -p "/sys/fs/cgroup/${cg}"
    sudo mount -t cgroup -o "${opts},${cg}" "${cg}" "/sys/fs/cgroup/${cg}" \
    || sudo rmdir "/sys/fs/cgroup/${cg}"
  fi
done

sudo ../runc delete --force mycontainerid

sudo ../runc --debug run mycontainerid
cd ..
