#!/usr/bin/env bash
# /pm-engine 执行脚本
# 用法：
#   pm-engine.sh <role> <engine>   # 设置
#   pm-engine.sh status           # 查看
#   pm-engine.sh reset            # 全部切回 cc

set -eo pipefail

CONFIG_FILE="${CONFIG_FILE:-.claude/engine-config.json}"

# role 别名 → 规范名
resolve_role() {
  case "$1" in
    4a|architect) printf '4a' ;;
    frontend|fe)  printf 'frontend' ;;
    *) echo "ERROR: 未知角色 '$1'（支持：4a/architect、frontend/fe）" >&2; exit 1 ;;
  esac
}

# role 允许的引擎
allowed_engines_for() {
  case "$1" in
    4a)        printf 'cc codex' ;;
    frontend)  printf 'cc gemini agy' ;;
    *) echo "ERROR: 内部错误，未知 role '$1'" >&2; exit 1 ;;
  esac
}

cmd="${1:-}"

case "$cmd" in
  status)
    if [ -f "$CONFIG_FILE" ]; then
      ENGINE_4A=$(python3 -c "import json;print(json.load(open('$CONFIG_FILE')).get('4a','cc'))")
      ENGINE_FE=$(python3 -c "import json;print(json.load(open('$CONFIG_FILE')).get('frontend','cc'))")
    else
      ENGINE_4A="cc"; ENGINE_FE="cc"
    fi
    echo "当前引擎配置（$CONFIG_FILE）："
    [ -f "$CONFIG_FILE" ] && cat "$CONFIG_FILE" || echo "  （文件不存在，全部角色默认 cc）"
    echo
    echo "  4a        → $ENGINE_4A"
    echo "  frontend  → $ENGINE_FE"
    ;;

  reset)
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<'JSON'
{
  "4a": "cc",
  "frontend": "cc"
}
JSON
    echo "✅ 已重置：4a=cc, frontend=cc"
    ;;

  "")
    echo "用法："
    echo "  /pm-engine <role> <engine>    # 设置（role: 4a/architect/frontend/fe；engine: cc/codex/gemini/agy）"
    echo "  /pm-engine status             # 查看当前配置"
    echo "  /pm-engine reset              # 全部切回 cc"
    ;;

  *)
    role_raw="$cmd"
    engine="${2:-}"
    if [ -z "$engine" ]; then
      echo "ERROR: 缺少 engine 参数。用法：/pm-engine <role> <engine>" >&2
      exit 1
    fi
    role=$(resolve_role "$role_raw")
    allowed=$(allowed_engines_for "$role")
    if ! echo " $allowed " | grep -q " $engine "; then
      echo "ERROR: role '$role' 不允许 engine '$engine'。允许：$allowed" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$CONFIG_FILE")"
    python3 - "$CONFIG_FILE" "$role" "$engine" <<'PY'
import json, sys
path, role, engine = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    cfg = json.load(open(path))
except FileNotFoundError:
    cfg = {}
cfg[role] = engine
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write('\n')
PY
    echo "✅ $role → $engine"
    echo "已写入 $CONFIG_FILE："
    cat "$CONFIG_FILE"
    echo
    echo "生效时机：下次派单开始。"
    ;;
esac
