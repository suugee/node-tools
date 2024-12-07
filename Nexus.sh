#!/bin/sh

# 设置版本号
current_version=2024120701

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 权限运行此脚本！"
    exit 1
fi

NEXUS_HOME=$HOME/.nexus
REPO_PATH=$NEXUS_HOME/network-api


# 安装基础环境
function install_dep(){
sudo apt update
sudo apt install -y git curl screen protobuf-compiler
rustc --version || curl https://sh.rustup.rs -sSf | sh
}

# 运行测试网
function start_testnet(){

PROVER_ID=$(cat $NEXUS_HOME/prover-id 2>/dev/null)
if [ "${#PROVER_ID}" -ne "28" ]; then
    echo To receive credit for proving in Nexus testnets, click on your prover id
    echo "(bottom left) at https://beta.nexus.xyz/ to copy the full prover id and"
    echo paste it here. Press Enter to continue.
    read -p "Prover Id (optional)> " PROVER_ID </dev/tty
    while [ ! ${#PROVER_ID} -eq "0" ]; do
        if [ ${#PROVER_ID} -eq "28" ]; then
            if [ -f "$NEXUS_HOME/prover-id" ]; then
                echo Copying $NEXUS_HOME/prover-id to $NEXUS_HOME/prover-id.bak
                cp $NEXUS_HOME/prover-id $NEXUS_HOME/prover-id.bak
            fi
            echo "$PROVER_ID" > $NEXUS_HOME/prover-id
            echo Prover id saved to $NEXUS_HOME/prover-id.
            break;
        else
            echo Unable to validate $PROVER_ID. Please make sure the full prover id is copied.
        fi
        read -p "Prover Id (optional)> " PROVER_ID </dev/tty
    done
fi

if [ -d "$REPO_PATH" ]; then
  echo "$REPO_PATH exists. Updating.";
  (cd $REPO_PATH && git stash save && git fetch --tags)
else
  mkdir -p $NEXUS_HOME
  (cd $NEXUS_HOME && git clone https://github.com/nexus-xyz/network-api)
fi

(cd $REPO_PATH && git -c advice.detachedHead=false checkout $(git rev-list --tags --max-count=1))

#等待修改成测试网 (cd $REPO_PATH/clients/cli && cargo run --release --bin prover -- beta.orchestrator.nexus.xyz)

}

# 运行开发网
function start_devnet(){

PROVER_ID=$(cat $NEXUS_HOME/prover-id 2>/dev/null)
if [ "${#PROVER_ID}" -ne "28" ]; then
    echo To receive credit for proving in Nexus testnets, click on your prover id
    echo "(bottom left) at https://beta.nexus.xyz/ to copy the full prover id and"
    echo paste it here. Press Enter to continue.
    read -p "Prover Id (optional)> " PROVER_ID </dev/tty
    while [ ! ${#PROVER_ID} -eq "0" ]; do
        if [ ${#PROVER_ID} -eq "28" ]; then
            if [ -f "$NEXUS_HOME/prover-id" ]; then
                echo Copying $NEXUS_HOME/prover-id to $NEXUS_HOME/prover-id.bak
                cp $NEXUS_HOME/prover-id $NEXUS_HOME/prover-id.bak
            fi
            echo "$PROVER_ID" > $NEXUS_HOME/prover-id
            echo Prover id saved to $NEXUS_HOME/prover-id.
            break;
        else
            echo Unable to validate $PROVER_ID. Please make sure the full prover id is copied.
        fi
        read -p "Prover Id (optional)> " PROVER_ID </dev/tty
    done
fi

if [ -d "$REPO_PATH" ]; then
  echo "$REPO_PATH exists. Updating.";
  (cd $REPO_PATH && git stash save && git fetch --tags)
else
  mkdir -p $NEXUS_HOME
  (cd $NEXUS_HOME && git clone https://github.com/nexus-xyz/network-api)
fi

(cd $REPO_PATH && git -c advice.detachedHead=false checkout $(git rev-list --tags --max-count=1))

(cd $REPO_PATH/clients/cli && screen -mS nexus cargo run --release --bin prover -- beta.orchestrator.nexus.xyz)

echo "看到成功信息后按键盘：Ctrl+a+d退出"

}

# 查看日志
function view_logs(){
    screen -r nexus
}

# 更新脚本
function update_script(){
    # 指定URL
    update_url=""
    file_name=$(basename "$update_url")

    # 下载脚本文件
    tmp=$(date +%s)
    timeout 10s curl -s -o "$HOME/$tmp" -H "Cache-Control: no-cache" "$update_url?$tmp"
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        echo "命令超时"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        echo "下载失败"
        return 1
    fi

    # 检查是否有新版本可用
    latest_version=$(grep -oP 'current_version=([0-9]+)' $HOME/$tmp | sed -n 's/.*=//p')

    if [[ "$latest_version" -gt "$current_version" ]]; then
        clear
        echo ""
        # 提示需要更新脚本
        printf "\033[31m脚本有新版本可用！当前版本：%s，最新版本：%s\033[0m\n" "$current_version" "$latest_version"
        echo "正在更新..."
        sleep 3
        mv $HOME/$tmp $HOME/$file_name
        chmod +x $HOME/$file_name
        exec "$HOME/$file_name"
    else
        # 脚本是最新的
        rm -f $tmp
    fi
}

# 退出cli
function quit_cli(){
    screen -X -S nexus quit
}

# 菜单显示
show_menu() {
  clear
  echo_yellow "============== Nexus 一键管理脚本 =============="
  echo_green "1. 安装Rust环境"
  echo_green "2. 启动TestNet"
  echo_green "3. 启动Devnet"
  echo_green "4. 查看运行日志(ctrl+a d退出)"
  echo_green "5. 更新脚本"
  echo_green "6. 关闭挖矿"
  echo_green "0. 退出脚本"
  echo_yellow "=============================================="
  read -p "请选择一个操作: " choice
  case $choice in
    1) install_dep ;;
    2) start_testnet ;;
    3) start_devnet ;;
    4) view_logs ;;
    5) update_script ;;
    6) quit_cli ;;
    0) exit 0 ;;
    *) echo_red "无效的选项，请重新选择。"; sleep 2; show_menu ;;
  esac
}



