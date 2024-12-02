#!/bin/bash

DB_DIR="/opt/hyperlane_db"
HYPERLANE_CONTAINER_NAME="hyperlane"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 权限运行此脚本！"
    exit 1
fi

# 检查并创建数据库目录
if [ ! -d "$DB_DIR" ]; then
    mkdir -p "$DB_DIR" && chmod -R 777 "$DB_DIR" || {
        echo "创建数据库目录失败: $DB_DIR"
        exit 1
    }
    echo "数据库目录已创建: $DB_DIR"
fi

# 安装 Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "安装 Docker..."
        apt-get update
        apt-get install -y docker.io || {
            echo "安装 Docker 失败！"
            exit 1
        }
        systemctl start docker
        systemctl enable docker
        echo "Docker 已安装！"
    else
        echo "Docker 已安装，跳过此步骤。"
    fi
}

# 安装 Node.js 和 NVM
install_nvm_and_node() {
    if ! command -v nvm &> /dev/null; then
        echo "安装 NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash || {
            echo "安装 NVM 失败！"
            exit 1
        }
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        echo "NVM 安装完成！"
    fi

    if ! command -v node &> /dev/null; then
        echo "安装 Node.js v20..."
        nvm install 20 || {
            echo "安装 Node.js 失败！"
            exit 1
        }
        echo "Node.js 安装完成！"
    fi
}

# 安装 Hyperlane
install_hyperlane() {
    if ! command -v hyperlane &> /dev/null; then
        echo "安装 Hyperlane CLI..."
        npm install -g @hyperlane-xyz/cli || {
            echo "安装 Hyperlane CLI 失败！"
            exit 1
        }
        echo "Hyperlane CLI 安装完成！"
    fi

    if ! docker images | grep -q 'gcr.io/abacus-labs-dev/hyperlane-agent'; then
        echo "拉取 Hyperlane 镜像..."
        docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 || {
            echo "拉取 Hyperlane 镜像失败！"
            exit 1
        }
        echo "Hyperlane 镜像拉取完成！"
    fi
}

# 启动节点bsctestnet
install_and_start_bsctestnet() {


    read -p "请输入 Validator Name: " VALIDATOR_NAME

    while true; do
        read -p "请输入 Private Key (格式：0x+64位十六进制字符): " PRIVATE_KEY
        echo ""
        if [[ ! 0x$PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            echo "无效的 Private Key 格式！"
        else
            break
        fi
    done

    read -p "请输入 RPC URL: " RPC_URL

    docker run -d \
        --name "$HYPERLANE_CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db \
        --originChainName bsctestnet \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db/bsctestnet_checkpoints \
        --validator.key "0x$PRIVATE_KEY" \
        --chains.bsctestnet.signer.key "0x$PRIVATE_KEY" \
        --chains.bsctestnet.customRpcUrls "$RPC_URL" &

    echo "节点已成功启动，日志可以通过查看容器日志获取。"
}

# 启动节点arbitrum
install_and_start_arbitrum() {

    read -p "请输入 Validator Name: " VALIDATOR_NAME

    while true; do
        read -p "请输入 Private Key (格式：0x+64位十六进制字符): " PRIVATE_KEY
        echo ""
        if [[ ! 0x$PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            echo "无效的 Private Key 格式！"
        else
            break
        fi
    done

    read -p "请输入 RPC URL: " RPC_URL

    docker run -d \
        --name "$HYPERLANE_CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db \
        --originChainName arbitrum \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db/arbitrum_checkpoints \
        --validator.key "0x$PRIVATE_KEY" \
        --chains.arbitrum.signer.key "0x$PRIVATE_KEY" \
        --chains.arbitrum.customRpcUrls "$RPC_URL" &

    echo "节点已成功启动，日志可以通过查看容器日志获取。"
}

# 启动节点sepolia
install_and_start_sepolia() {
    read -p "请输入 Validator Name: " VALIDATOR_NAME

    while true; do
        read -p "请输入 Private Key (格式：0x+64位十六进制字符): " PRIVATE_KEY
        echo ""
        if [[ ! 0x$PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            echo "无效的 Private Key 格式！"
        else
            break
        fi
    done

    read -p "请输入 RPC URL: " RPC_URL

    docker run -d \
        --name "$HYPERLANE_CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db \
        --originChainName sepolia \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db/sepolia_checkpoints \
        --validator.key "0x$PRIVATE_KEY" \
        --chains.sepolia.signer.key "0x$PRIVATE_KEY" \
        --chains.sepolia.customRpcUrls "$RPC_URL" &

    echo "节点已成功启动，日志可以通过查看容器日志获取。"
}


# 启动节点polygon
install_and_start_polygon() {

    read -p "请输入 Validator Name: " VALIDATOR_NAME

    while true; do
        read -p "请输入 Private Key (格式：0x+64位十六进制字符): " PRIVATE_KEY
        echo ""
        if [[ ! 0x$PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            echo "无效的 Private Key 格式！"
        else
            break
        fi
    done

    read -p "请输入 RPC URL: " RPC_URL

    docker run -d \
        --name "$HYPERLANE_CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db \
        --originChainName polygon \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db/polygon_checkpoints \
        --validator.key "0x$PRIVATE_KEY" \
        --chains.polygon.signer.key "0x$PRIVATE_KEY" \
        --chains.polygon.customRpcUrls "$RPC_URL" &

    echo "节点已成功启动，日志可以通过查看容器日志获取。"
}

# 启动节点celo
install_and_start_celo() {
    read -p "请输入 Validator Name: " VALIDATOR_NAME

    while true; do
        read -p "请输入 Private Key (格式：0x+64位十六进制字符): " PRIVATE_KEY
        echo ""
        if [[ ! 0x$PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            echo "无效的 Private Key 格式！"
        else
            break
        fi
    done

    read -p "请输入 RPC URL: " RPC_URL

    docker run -d \
        --name "$HYPERLANE_CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db \
        --originChainName celo \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db/celo_checkpoints \
        --validator.key "0x$PRIVATE_KEY" \
        --chains.celo.signer.key "0x$PRIVATE_KEY" \
        --chains.celo.customRpcUrls "$RPC_URL" &

    echo "节点已成功启动，日志可以通过查看容器日志获取。"
}

# 启动节点linea
install_and_start_linea() {
    read -p "请输入 Validator Name: " VALIDATOR_NAME

    while true; do
        read -p "请输入 Private Key (格式：0x+64位十六进制字符): " PRIVATE_KEY
        echo ""
        if [[ ! 0x$PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            echo "无效的 Private Key 格式！"
        else
            break
        fi
    done

    read -p "请输入 RPC URL: " RPC_URL

    docker run -d \
        --name "$HYPERLANE_CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db \
        --originChainName linea \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path /hyperlane_db/linea_checkpoints \
        --validator.key "0x$PRIVATE_KEY" \
        --chains.linea.signer.key "0x$PRIVATE_KEY" \
        --chains.linea.customRpcUrls "$RPC_URL" &

    echo "节点已成功启动，日志可以通过查看容器日志获取。"
}

install_dep(){
    install_docker
    install_nvm_and_node
    install_hyperlane
}


# 查看容器日志
view_container_log() {
    if docker ps -a | grep -q "$HYPERLANE_CONTAINER_NAME"; then
        echo "显示 Hyperlane 容器日志："
        docker logs --tail 100 -f "$HYPERLANE_CONTAINER_NAME"
    else
        echo "Hyperlane 容器未运行，无法查看日志！"
    fi
}

# 卸载 Hyperlane
uninstall_hyperlane() {
    if docker ps -a | grep -q "$HYPERLANE_CONTAINER_NAME"; then
        echo "正在停止并删除 Hyperlane 容器..."
        docker stop "$HYPERLANE_CONTAINER_NAME"
        docker rm "$HYPERLANE_CONTAINER_NAME"
        echo "Hyperlane 容器已卸载。"
    else
        echo "Hyperlane 容器不存在，跳过此步骤。"
    fi

    echo "卸载完成（未移除依赖）。"
}

# 主菜单
main_menu() {
    while true; do
        echo "================= Hyperlane 管理脚本 ================="
        echo "1) 安装基础环境"
        echo "2) 安装并启动bsctestnet节点"
        echo "3) 安装并启动arbitrum节点"
        echo "4) 安装并启动sepolia节点"
        echo "5) 安装并启动celo节点"
        echo "6) 安装并启动polygon节点"
        echo "7) 安装并启动linea节点"
        echo "8) 查看容器日志"
        echo "9) 卸载节点 (不卸载依赖)"
        echo "0) 退出脚本"
        echo "====================================================="
        read -p "请输入选项: " choice
        case $choice in
            1) install_dep ;;
            2) install_and_start_bsctestnet ;;
            3) install_and_start_arbitrum ;;
            4) install_and_start_sepolia ;;
            5) install_and_start_celo ;;
            6) install_and_start_polygon ;;
            7) install_and_start_linea ;;
            8) view_container_log ;;
            9) uninstall_hyperlane ;;
            0) exit 0 ;;
            *) echo "无效选项，请重试！" ;;
        esac
    done
}

main_menu
