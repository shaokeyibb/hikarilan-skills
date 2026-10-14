# structural-fix

[English](README.md) | **简体中文**

在需求设计和 BUG 修复上优先采用系统性、结构化的代码设计。当提出一个需求或 BUG 修复的时候，首先考虑在整个仓库或上下游依赖中是否还有类似的同一模式，并在改动里一齐改动，而不是只动一个切面；尽量不通过兜底方案来掩盖问题，而是自底向上考虑是否有更好的方案。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill structural-fix
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
