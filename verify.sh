#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
easyuc_dsl="${EASYUC_DSL_DIR:-$HOME/Desktop/毕设/easyuc相关/EasyUC/uc-dsl}"
ucdsl=("$easyuc_dsl/bin/ucdsl" -I "$easyuc_dsl/common" -I "$easyuc_dsl/prelude")

easycrypt compile -no-eco VoteCore.ec
printf '%s\n' 'PASS EasyCrypt 投票与 QC 证明'

"${ucdsl[@]}" -units VoteDemo.uc
printf '%s\n' 'PASS EasyUC 模型类型检查'

"${ucdsl[@]}" -batch demo.uci
printf '%s\n' 'PASS EasyUC 真实世界与理想世界演示断言'
