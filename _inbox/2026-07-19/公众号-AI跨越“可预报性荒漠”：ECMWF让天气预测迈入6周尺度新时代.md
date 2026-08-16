---
title: 公众号-AI跨越“可预报性荒漠”：ECMWF让天气预测迈入6周尺度新时代
author: ControlRun
url: https://mp.weixin.qq.com/s/P6Or7Oo_KMTEDN3yjec32Q
synced_at: 2026-07-18T16:50:11.237Z
source: 公众号图文
---

<!-- wechat-inbox-record-id: 786aa83e6a5baebe036ca3fc4fe94df5 -->

## Markdown 内容

![论文封面](https://mmbiz.qpic.cn/mmbiz_png/SgR2Za9GiaQcflJOrOZicCoYwg2aLC2ibqmCHYvwzGG4CbGqVWjVhOsO1UIs35FoUZMeKQYS8ntfceK8lTSP2g8zSLjypbrw9RMxemZrAQHpGI/640?wx_fmt=png&from=appmsg)

研究概览

论文标题：AIFS-SUBS: Extending Data-Driven Forecasting to Sub-Seasonal Timescales
作者（均为ECMWF）：Jakob Schloer, Steffen Tietsche, Christopher D. Roberts, Lorenzo Zampieri, Simon Lang, Gert Mertes, Gareth Jones, Matthew Chantry, Frederic Vitart
模型：~230M 参数，16层 graph-transformer，嵌入维度 1024，8头注意力 | 16× A100 GPU，~4天预训练
核心问题：数据驱动模型（GraphCast、AIFS、Pangu等）已在中程（1-10天）接近甚至超越NWP，但次季节（第2-6周）——介于初始条件主导的中程和边界条件主导的季节预测之间的"可预报性荒漠"——AIFS-SUBS 是目前少数专门针对次季节尺度优化的数据驱动预测系统之一，并首次达到与业务IFS直接比较的水平（此前已存在 FuXi-S2S 等次季节 ML 模型）。
突破手段：四项改造——(1) 24h自回归步长（原6h）；(2) 加入平流层+大气顶热辐射；(3) 2007-2011年独立验证窗口；(4) 双配置策略（业务分析场微调版 + 纯ERA5版）。
关键结论：MJO对流分量预报技巧领先IFS 8天；平流层爆发性增温（SSW）频率和地面影响准确再现；AI Weather Quest 第3-4周平均RPSS略超IFS；推理能耗仅IFS的~1/200。

方法：四项关键改造

AIFS-SUBS 从 ECMWF 现有的 AIFS-CRPS 中程模型改造而来，整体架构为 16 层 graph-transformer，通过自回归方式将预报从 6 小时步长扩展到第 6 周。其核心方法包括以下四项关键改造：

![Figure 1](https://mmbiz.qpic.cn/mmbiz_jpg/SgR2Za9GiaQfcV1L9iby2fazaPDxKQrRpqNRViaevWUf4ZpMesyLJnO2U6AL3b7rom3zmjRItY6daXMb65FDrTFSh34hpebuRpWwC2ldzP2ibias/640?wx_fmt=jpeg&from=appmsg)

Figure 1 | AIFS-SUBS 训练与评估协议。展示了从AIFS-CRPS中程模型出发的四项关键改造：(a) 24h自回归步长替代6h；(b) 训练/验证/测试数据划分方案（ERA5 1979-2006训练，2007-2011独立验证，2012-2021测试）；(c) 双配置策略——AIFS-SUBS（业务分析场微调）和AIFS-SUBS-ERA5（纯ERA5训练）。来源：Schloer et al. (2026), Fig. 1。

AIFS-SUBS 从 ECMWF 现有的 AIFS-CRPS 中程模型改造而来。四项改造的设计逻辑：

改造1：24小时自回归步长。中程模型使用6小时步长——若延伸到第6周（42天），需要自回归 168 次。每次迭代的误差累积使第3周后的预报迅速退化。将步长改为24小时后，仅需 42 次自回归。这不仅是减少了自回归次数——更重要的是改变了模型的学习目标：6h模型学习的是短时间尺度动力传播，24h模型学习的是日尺度低频状态演变。代价是丧失了日循环的显式表示（如午后对流），但在次季节评分中，周平均指标远比日循环准确度重要。
改造2：平流层变量 + 大气顶热辐射。模型新增了至 2 hPa 的平流层层次，以及 ttr（顶大气层热辐射，用于推导OLR）。这不是锦上添花——平流层-对流层耦合是次季节可预报性的两大核心来源之一（另一个是 MJO）。平流层爆发性增温（SSW）发生后，其异常信号向下传播进入对流层，可在 2-4 周后调制北大西洋涛动（NAO）和中纬度阻塞形势——这是"次季节记忆"的核心物理机制。
改造3：2007-2011年独立验证窗口。次季节技能评估依赖稀有事件——MJO 每年仅约 4-6 个完整周期，SSW 每年仅 1-2 次。必须预留足够长的独立验证期（5年）才能获得统计显著的评估。代价是减少训练数据——在数据驱动模型中是一个难得的科学诚实做法。
改造4：双配置策略。AIFS-SUBS 在 ERA5 + 业务分析场（IFS cycle 49r1）上微调，面向实时预报。AIFS-SUBS-ERA5 仅用 ERA5 训练，提交至 AI Weather Quest 比赛（代号 AIFSgaia），避免使用业务分析场带来的不公平优势。

核心发现一：系统性偏差全面降低

![Figure 2](https://mmbiz.qpic.cn/sz_mmbiz_jpg/SgR2Za9GiaQcEU1KcX0bCMtI7kqLXykrRXibzctibe7iaZfwUUR0ShF7TwSHm0icw3hDyQFxE2dp9FmRiaOzkItibJJLrBkUibTOmDJ2XOPcGhShrFk/640?wx_fmt=jpeg&from=appmsg)

Figure 2 | AIFS-SUBS 偏差降低及概率技能对比。(a) 相对于 IFS (49r1) 的 MABS 变化——蓝色表示 AIFS-SUBS 偏差更小。(b) fCRPSS——红色表示 AIFS-SUBS 概率技能优于 IFS。热带区平流层变量（如 50 hPa 纬向风）在所有时效上显著改进，暗示 AIFS-SUBS 对 QBO 的表征优于 IFS。来源：Schloer et al. (2026), Fig. 2。

偏差降低：AIFS-SUBS 在第 1-6 周全变量上系统性降低偏差（相对于 IFS 49r1）。热带区偏差降低超过 5%——这是最具操作意义的改进，因为热带气旋和 MJO 活动集中于此。两个例外：(1) 500 hPa 位势高度——AIFS-SUBS 比 IFS 差；(2) 平均海平面气压在第 3 周后与 IFS 持平。
概率技能（fCRPSS）：北半球中纬度——AIFS-SUBS 与 IFS 总体持平，第 1 周地表变量略有改善。热带区——第 1-2 周地表和对流层变量显著优于 IFS，之后持平。最引人注目的是平流层变量（尤其是 50 hPa 纬向风）——在所有时效上显著优于 IFS，暗示 AIFS-SUBS 对准两年振荡（QBO）的表征能力优于 IFS。QBO 是赤道平流层东西风的准周期交替（~28个月），对 MJO 传播和 SSW 发生概率有直接影响——AIFS-SUBS 能有效利用与 QBO 相关的低频信息。但论文未做表征分析（如 attention analysis、latent variable analysis），因此模型是否形成了类似物理模式中的 QBO 机制表示仍需进一步验证——当前的表现也可能源于对年循环、SST 关联等其他统计关系的学习。

核心发现二：MJO预报——领先IFS 8天

![Figure 3](https://mmbiz.qpic.cn/sz_mmbiz_jpg/SgR2Za9GiaQfGjaPiaoo5y0pkKxZ069KWgY8ibYC4LreHzReqkBzC0KhpXNia9ibsXTaG8gaWeHQGBsSBC5riaySicDBiauPG9Y6P1u0YCED43oatib8/640?wx_fmt=jpeg&from=appmsg)

Figure 3 | MJO预报技巧——AIFS-SUBS vs IFS。(a,b) 双变量相关（COR）；(c,d) fCRPSS；(e,f) 振幅偏差。左列为全多变量RMM指数，右列为仅OLR对流分量。AIFS-SUBS在OLR分量上将技能性预报（corr > 0.5）延长了约8天。来源：Schloer et al. (2026), Fig. 3。

这是全文最引人注目的结果。在 RMM 全多变量指数上，AIFS-SUBS 与 IFS 相当或略优。但在 OLR 对流分量——MJO 的纯对流信号——上，AIFS-SUBS 将技能性预报（双变量相关 > 0.5）延长了约 8 天。从数字上看：IFS 在约 25 天时 OLR 相关性降至 0.5 以下，而 AIFS-SUBS 在约 33 天时仍保持 0.5 以上的相关——这意味着 MJO 的可用预报跨越了从"第 3 周末"到"第 5 周末"的鸿沟。

为什么是 OLR 分量而不是全 RMM 指数？RMM 指数的风场分量（850/200 hPa 纬向风）主要反映大尺度环流响应，NWP 对此已有较好的表征。但 MJO 的对流核心——深对流云的消长和东传——需要正确表示对流-辐射-环流的耦合反馈链。IFS 的积云参数化方案（对流触发-抑制-组织化）是已知的系统性误差来源——尤其是在海洋性大陆（Maritime Continent）区域对流传播的"屏障效应"上。AIFS-SUBS 在 OLR 分量上的优势可能源于多因素——包括更高的数据拟合能力、模型容量差异、损失函数设计和平滑误差特性——其中 IFS 积云参数化方案的已知系统性偏差可能是重要贡献因素之一，但论文未直接证明因果关系。

更多关键结果

3. SSW频率和地面影响：AIFS-SUBS 在 10-36 天预报中产生了 112 个 SSW 事件（频率与 ERA5 观测一致），其中 51% 具有强地面影响。这是数据驱动模型首次在次季节尺度上自发再现平流层极端事件及其向下传播——AIFS-SUBS 并未显式求解平流层动力方程，但其训练数据（ERA5）本身来自 IFS 同化系统——已经包含了完整物理模式产生的信息。更准确的理解是：AI 模型没有显式编码中层大气物理参数化，但从再分析数据中学习到了 SSW 相关演变模式。
4. 热带气旋的 MJO 调制：AIFS-SUBS 成功再现了观测中 MJO 相位调制热带气旋活动的模式——MJO 对流活跃相（相位 4-7，西太平洋）对应 TC 活动增强。这对次季节 TC 活动展望（如 NOAA 的 Global Tropics Hazards Outlook）有直接业务价值。
5. AI Weather Quest 成绩：AIFS-SUBS-ERA5 在第 3-4 周的三变量平均 RPSS 略超 IFS——注意这是在仅使用 ERA5 训练（未使用业务分析场微调）的条件下。2m 温度和降水在第 3 周显著优于 IFS（Fig. 6c），尤其在欧洲和北美地区。
6. 推理能耗——200倍的差距：AIFS-SUBS 单次推理能耗约为 IFS 51 成员集合的 1/200。这开启了一个全新可能：超大规模实时集合预报——1000+ 成员的次季节集合，用于直接采样稀有极端事件的概率（而无需依赖统计后处理）。

局限性

1. Z500 是明显弱点：AIFS-SUBS 在 500 hPa 位势高度上的偏差大于 IFS——这是中纬度预报的核心变量。可能原因：24h 步长无法解析 Rossby 波包的快速传播（群速度可达 30 m/s），导致波导上的位相误差累积。
2. 集合扰动策略未优化：当前集合通过初始条件扰动生成，未针对次季节尺度的误差增长特征（如 MJO 的集合离散不足问题）进行优化。
3. 海洋耦合缺失：AIFS-SUBS 使用预设的海表温度——无法表征海气耦合反馈（如 MJO 引起的 SST 异常对对流组织的正反馈）。这是 FuXi-S2S（耦合海洋分量）相对 AIFS-SUBS 的已知优势。
4. 实时预报验证有限：虽然展示了 2025-2026 年冬季的实时个例（SSW 2009年1月、MJO 事件），但系统性的实时业务验证尚在进行中。

结论

1. ECMWF 成功将数据驱动预报从"中程"扩展到"次季节"——这是 AI 气象预报从初始条件主导进入边界条件-内部变率混合时间尺度的里程碑。
2. MJO 对流分量的 +8 天技能延长是全文最亮的结果——对全球次季节水文气象预报（如印度季风活跃/中断期、澳洲季风 onset）有直接业务价值。
3. AIFS-SUBS 尽管其训练数据（ERA5）本身来自 IFS 同化系统的物理约束，但模型未显式编码中层大气物理参数化即能再现 SSW 频率和向下传播——这是数据驱动模型物理一致性的有力证据。
4. 200 倍的推理能效差距使超大规模集合成为可能——这可能在次季节极端事件概率预测中产生质的飞跃。
5. Z500 的弱点、集合扰动策略、海洋耦合的缺失——是 AIFS-SUBS 进入业务前需要解决的三大瓶颈。
