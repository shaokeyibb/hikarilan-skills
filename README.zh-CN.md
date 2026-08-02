# hikarilan-skills

[English](README.md) | **简体中文**

给 [Claude Code](https://claude.com/claude-code) 用的 agent skill，全部从长时间、多 agent 的开发会话里真实翻过的车中提炼而来。

其中四个共享同一个性质：**它们针对的失败，方向全都是「看起来成功」**——绿的测试、笃定的报告、干净的 `git status`、读起来很充分的审计，没有一个会报错。会报错的问题不需要纪律，它自己会浮上来；这些不会。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills
```

该命令会读取仓库中的全部 skill，供你选择安装其中一部分或全部。

只装某一个：

```bash
npx skills add shaokeyibb/hikarilan-skills --skill false-green
```

## Skill 一览

### `false-green` — 假绿

建立绿灯值得相信的检查，并在宣称通过之前证明它。

- 一个检查的绿要有意义，需要三个属性：**失败必须经由你实际跑的那条路可观察**；**「未验证」是独立的第三态**，永远不与「通过」共用退出码；**定义只有一处**，所有入口都调用它
- 会把红静默翻成绿的已知形态：管道吞掉退出码、缺席被读作零、空集合恒真、搜索被截断、跑的根本不是你改的那份代码
- 怎么判断一条测试是否真的锁住了它声称锁住的东西——变异要打在**那条具体语义**上，打在功能开关上必然全红，证明不了任何事

### `delegating-to-agents` — 委派给子代理

决定什么该交给子代理，把任务书写成约束真能生效的结构，并在结论回来后自核。

- 可委派性只有一个判据：**这个结果能否在不重做的前提下被验证？**
- 三类措辞买不到的行为——只读、等后台任务真跑完、待在自己的工作目录里——以及各自的结构替代
- 为什么只给禁令不给替代手段一定会被绕过；以及代理的报告在成为证据之前必须核什么

### `concurrent-worktrees` — 并发工作树

用 git worktree 并行推进多条工作线，并在合并回来时不丢任何人的改动。

- worktree 到底买来了什么、代价是什么（一棵新树没有环境），以及由此推出的打包规则
- 编排者模式：谁建树、谁合并，以及破坏性 git 为什么永不下放
- 未提交的工作不是存储；diff 要钉死 base SHA 而不是分支名；判断能否并行看的是**共享门禁**，不是文件是否重叠

### `batch-closeout` — 批次收尾

一批工作在进入验收之前的收口。

- 一个「批次」是共享**同一次验收信号**的一组工作——而其中任何一个带着已知缺陷，就污染了全批的信号
- 缺陷账本：报告提到的那一刻就登记，验收**之前**清零，剩下的写成有边界的债务
- 多 lens 终局审计，且各个 lens 必须以**不同的方式**失败；发现在修之前先做对抗性确认

### `matt-skills-on-openspec` — 把 matt skill 接到 OpenSpec 上

把 [Matt Pocock 的工程 skill](https://github.com/mattpocock/skills) 接到以 [OpenSpec](https://github.com/Fission-AI/OpenSpec) change 作为工作项的仓库上。

- 哪个 skill 对应哪份 change artifact 或哪条 `/opsx` 命令，逐节给出——且每一节只在你装了那个 skill 时才适用
- 值得知道的模板冲突：一份 spec 怎么拆进三个 artifact、阻塞关系怎么落进线性清单
- 完全不需要适配的那九个 skill

## 许可

[MIT](LICENSE)
