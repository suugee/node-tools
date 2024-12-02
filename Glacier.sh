#!/bin/bash

# 彩色输出函数
echo_green() { echo -e "\033[32m$1\033[0m"; }
echo_red() { echo -e "\033[31m$1\033[0m"; }
echo_yellow() { echo -e "\033[33m$1\033[0m"; }

# 菜单显示
show_menu() {
  clear
  echo_yellow "============== Glacier 一键管理脚本 =============="
  echo_green "1. 启动节点"
  echo_green "2. 查看节点日志"
  echo_green "3. 退出"
  echo_yellow "=============================================="
  read -p "请选择一个操作: " choice
  case $choice in
    1) start_node ;;
    2) view_logs ;;
    3) exit 0 ;;
    *) echo_red "无效的选项，请重新选择。"; sleep 2; show_menu ;;
  esac
}

# 启动节点函数
start_node() {
  read -p "请输入您的私钥: " PRIVATE_KEY
  if [ -z "$PRIVATE_KEY" ]; then
    echo_red "私钥不能为空！"
    sleep 2
    show_menu
  fi
  echo_green "启动节点中..."
  docker run -d -e PRIVATE_KEY=0x$PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.2
  if [ $? -eq 0 ]; then
    echo_green "节点启动成功！"
  else
    echo_red "节点启动失败，请检查日志。"
  fi
  sleep 2
  show_menu
}

# 查看日志函数
view_logs() {
  echo_green "正在查看节点日志（按 Ctrl+C 退出）..."
  docker logs -f glacier-verifier
  sleep 2
  show_menu
}

# 启动脚本
show_menu
