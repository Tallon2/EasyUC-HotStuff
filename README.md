# HotStuff Prepare 投票与 QC 演示

示例固定一个会话、一轮 Prepare 和一个区块，使用 `(sid, view, phase, block) = (1, 1, 0, 42)`。初始化时登记四个不同的环境端口，依次代表节点 0–3。收集器按 EasyUC 消息来源端口识别节点，每个节点对应一个布尔位。收到合法新票时设置该位，至少三个不同节点投票时返回 `qc=true`。

## 运行

```bash
cd /Users/cengang/Desktop/xx/easyuc/hotstuff-uc-minimal
./verify.sh
```

需要 PATH 中的 `easycrypt` 以及参考源码目录下编译好的 `uc-dsl/bin/ucdsl`。参考源码位于其他位置时，用绝对路径设置 `EASYUC_DSL_DIR`，指向其 `uc-dsl` 目录。脚本依次重检 EasyCrypt 证明、对 EasyUC 模型做单元类型检查、运行解释器断言。需要逐步展示时，将脚本最后一条 EasyUC 命令的 `-batch` 换成 `-interpreter`。

## 给导师演示

`result(accepted, count, qc)` 依次表示本次是否计票、累计有效票数和当前是否达到门槛。真实世界按以下顺序执行。

| 输入 | 返回 |
| --- | --- |
| 节点 0 首次投合法票 | `(true, 1, false)` |
| 节点 0 重复投票 | `(false, 1, false)` |
| 未登记端口投票 | `(false, 1, false)` |
| 节点 1 分别使用错误会话、视图、阶段、区块 | 每次均为 `(false, 1, false)` |
| 节点 1 改投合法票 | `(true, 2, false)` |
| 节点 2 投合法票 | `(true, 3, true)` |
| 节点 2 再次投票 | `(false, 3, true)` |
| 节点 3 投合法票 | `(true, 4, true)` |
| 第 12 次投票请求为重复票 | `(false, 4, true)` |
| 第 13 次投票请求 | `fail_out` |

现场可先指出错误票和重放都没有抬高计数，再展示第二个合法节点仍拿不到 QC，第三个合法节点才使 QC 标志翻转。理想世界通过 `VoteSim` 完成初始化握手，随后复跑首次投票、重放、外部端口、两票不足和第三票成 QC。

## 证明与模型边界

- `VoteCore.ec` 的 `duplicate_is_noop` 和 `invalid_is_noop` 证明相应输入保持投票位图。 `step_count` 证明计数增量恰好是“票合法且此前未计入”的布尔值。
- `insufficient_votes_no_qc` 证明少于三票时 QC 为假。 `qc_has_three_distinct` 证明 QC 当且仅当四个可能的三节点组合中至少有一个已完整投票。 `quorum_intersection` 证明任意两个三票法定集合至少共享两个节点。
- `VoteDemo.uc` 的两个世界直接调用上述 EasyCrypt 转移。 `demo.uci` 在符号环境端口上核对指定消息序列，端口的环境归属和互异性是演示前提。
- 本例将身份认证抽象为消息端口归属，将 QC 抽象为门槛布尔值。模型固定单会话、单视图、单区块，并设定 12 次投票请求的执行预算，重复票和非法票也消耗预算。证明范围涵盖收票规则和法定集合性质。真实世界与理想世界的测试是有限轨迹检查，完整 UC 实现定理及 HotStuff 跨视图安全性、终止性均超出本例范围。
