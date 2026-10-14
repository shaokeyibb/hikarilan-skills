# concurrent-worktrees

[English](README.md) | **简体中文**

多 Agent 并行开发时的 git worktree 用法。多个 Agent 共用一棵工作树时，别人改到一半的文件会让你的提交钩子失败，别人一句 `git clean` 就能把你没提交的改动清掉。这个 Skill 讲什么时候值得开 worktree、怎么按文件邻域分批、由编排者统一建树和合并、破坏性 git 为什么永远不下放，以及合并回主干时怎么不丢任何人的改动。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill concurrent-worktrees
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
