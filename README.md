# Basic HotStuff 机械化验证

本仓库是 Basic HotStuff 机械化验证毕业论文的配套代码仓库，使用 EasyUC 描述协议参与方及其消息行为，使用 EasyCrypt 检查模型中的性质。仓库按实验周计划持续更新，每周围绕一个可复现的实验记录模型改动、运行命令、检查结果和待完成的证明义务。

## 当前公开进度

| 周次 | 实验 | 状态 |
| --- | --- | --- |
| 第 0 周 | 固定一个提案的 Prepare 收票与法定人数证书（QC）门槛 | 已公开，证明、类型和场景检查通过 |
| 第 1 周 | 同一视图中的双提案分别计票 | 下一项公开更新 |

当前版本固定四个成员和一个提案，投票上下文为 `(sid, view, phase, block) = (1, 1, 0, 42)`。每个成员的合法票只计一次，第三个不同成员投票时达到 QC 门槛。模型用消息来源端口代表节点身份，用布尔值表示是否达到门槛。收票预算为 12 次请求，第 13 次返回 `fail_out`。

EasyCrypt 已检查计票增量、重复票和非法票保持状态、三票门槛，以及四成员中任意两个三票法定集合至少共享两人的性质。EasyUC 已检查真实与理想模型中的指定消息轨迹。跨视图提交安全性、终止性和完整的 UC 实现定理是后续证明目标。

## 复现实验

准备好 PATH 中的 `easycrypt` 和已编译的 EasyUC DSL。将下方的路径换成 EasyUC 源码中的 `uc-dsl` 目录，该目录应包含 `bin/ucdsl`。

```bash
git clone https://github.com/Tallon2/EasyUC-HotStuff.git
cd EasyUC-HotStuff
export EASYUC_DSL_DIR="/path/to/EasyUC/uc-dsl"
bash verify.sh
```

脚本依次运行 EasyCrypt 证明检查、EasyUC 模型类型检查，以及真实与理想场景断言。三项均通过时退出码为 `0`。如需查看逐步消息输出，运行以下命令。

```bash
dsl="$EASYUC_DSL_DIR"
"$dsl/bin/ucdsl" -I "$dsl/common" -I "$dsl/prelude" -interpreter demo.uci
```

| 文件 | 用途 |
| --- | --- |
| [VoteCore.ec](VoteCore.ec) | 收票、去重和 QC 门槛的定义与证明 |
| [VoteDemo.uc](VoteDemo.uc) | EasyUC 真实模型、理想模型和演示用模拟器 |
| [demo.uci](demo.uci) | 投票、重放、非法票和预算耗尽的场景断言 |
| [verify.sh](verify.sh) | 一次执行全部检查 |

## 论文引用

引用整个项目时，可写作「Tallon2，Basic HotStuff 机械化验证，GitHub」。引用论文中的具体实验结果时，请附上对应周次和 Git 提交永久链接，方便读者复现当时使用的版本。从仓库提交历史进入指定提交即可取得链接。[项目仓库](https://github.com/Tallon2/EasyUC-HotStuff)

第 0 周基线对应提交 [`dad724e`](https://github.com/Tallon2/EasyUC-HotStuff/commit/dad724e640916a527112a9fdc5091862484b7383)。克隆后可运行 `git checkout dad724e640916a527112a9fdc5091862484b7383` 取得该版本，再按上面的步骤复现。
