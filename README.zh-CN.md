# hikarilan-skills

[English](README.md) | **简体中文**

一组 agent skill，适用于 [Claude Code](https://claude.com/claude-code) 以及其他支持 [Agent Skills](https://agentskills.io) 格式的编码 agent。每个 skill 各自独立，按需安装即可。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills
```

该命令会列出仓库中的全部 skill，由你选择安装哪些。只装某一个：

```bash
npx skills add shaokeyibb/hikarilan-skills --skill structural-fix
```

加上 `-g` 则装到用户级，而不是当前项目。

## Skill 一览

| Skill | 用途 |
|---|---|
| [`afk`](skills/afk/) | 你不在的时候让 agent 继续干活。小事自己定，能回退的先做、其余挂起等你裁决，定时巡检对齐进度，你回来时给出一份总结，所有待裁决的事一并交给你。 |
| [`capability-pruning`](skills/capability-pruning/) | 以能力为单位精简项目。先做全量盘点，再为每项能力写一张证据卡片，每一项删除都由负责人拍板。 |
| [`concurrent-worktrees`](skills/concurrent-worktrees/) | 用 git worktree 并行推进多条工作线，合并回来时不丢任何人的改动。 |
| [`e2e-first-testing`](skills/e2e-first-testing/) | 决定该写、该留、该删哪些测试。默认写经生产入口的端到端场景，替身只放在外部边界。附带按覆盖率删减旧测试的脚本。 |
| [`llm-agent-surface`](skills/llm-agent-surface/) | 规定 agent 框架里模型能看到什么（工具 schema、提示词、拒收信息），以及框架在哪里止步、交给模型决定。 |
| [`matt-skills-on-openspec`](skills/matt-skills-on-openspec/) | 把 [Matt Pocock 的工程 skill](https://github.com/mattpocock/skills) 接到以 [OpenSpec](https://github.com/Fission-AI/OpenSpec) change 作为工作项的仓库上。 |
| [`minimal-design-gate`](skills/minimal-design-gate/) | 防过度设计，查两次：动手前查方案，交付后查成品。 |
| [`repo-audit-loop`](skills/repo-audit-loop/) | 审计整个仓库或一批已完成的工作，一轮接一轮，直到某一轮什么都没找到。全程维护覆盖台账和缺陷台账。 |
| [`site-annotated-gates`](skills/site-annotated-gates/) | 用静态检查守住架构规则。每个例外都在代码现场标注，过期的标注同样报失败。附只用标准库的实现。 |
| [`structural-fix`](skills/structural-fix/) | 修复缺陷时让这一类问题整体消失，而不只修被报告的那一个实例。 |

## 许可

[MIT](LICENSE)
