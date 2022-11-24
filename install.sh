OS="linux"
WORKDIR="/opt/oci/"

# Check ARCH is amd64 or arm64
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

RELEASE_URL="https://github.com/testmediattt/nf_oci/releases/download/v0.0.1/oci_monitor_$OS_$ARCH"

# Download oci_monitor
cd $WORKDIR
curl -L -o $WORKDIR/oci_monitor $RELEASE_URL
chmod +x oci_monitor
# Download oci_monitor.service
curl -L -o oci.service https://raw.githubusercontent.com/testmediattt/nf_oci/main/oci.service
# Copy oci_monitor.service to /etc/systemd/system/
cp oci.service /etc/systemd/system/


# config oci_monitor
echo -e "请输入config配置文件:"

echo -e "例如输入：user=ocid1.user.oc1..aaaaaaaaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
read -p "请输入user:" user_ocid
echo -e "例如输入：fingerprint=a1:a1:a1:a1:a1:a1:a1:a1"
read -p "请输入fingerprint:" fingerprint
echo -e "例如输入：tenancy_ocid=ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
read -p "请输入tenancy_ocid:" tenancy_ocid
echo -e "例如输入：region=sa-saopaulo-1"
read -p "请输入region:" region

config="$user_ocid
$fingerprint
$tenancy_ocid
$region"

# 确认输入是否正确
echo -e "您输入的配置为："
echo -e "$config"
read -p "确认输入是否正确？(y/n)" confirm
if [ "$confirm" = "y" ]; then
    echo -e "$config" > /opt/oci/config
    echo -e "请输入key_file文件内容"
    read -p "key_file: " key_file
    echo -e "$key_file" > /opt/oci/key_file
    echo -e "配置完成"
else
    echo -e "请重新运行脚本"
    exit 1
fi

# 粘贴密钥
echo -e "请粘贴密钥"
read -p "key: " key

echo -e "正在配置..."
# 获得家目录
home=$(eval echo ~$user)
oci_config_dir="$home/.oci"
# 确认目录是否存在
if [ ! -d "$oci_config_dir" ]; then
    mkdir $oci_config_dir
fi
echo -e "$config" > $oci_config_dir/config
echo -e "$key" > $oci_config_dir/key.pem
echo "key_file=$oci_config_dir/key.pem" >> $oci_config_dir/config

echo -e "配置完成"
echo -e "正在启动"


# Start oci_monitor.service
systemctl daemon-reload
systemctl enable oci.service
systemctl start oci.service

echo -e "启动完成，运行systemctl stop oci.service可停止服务"
