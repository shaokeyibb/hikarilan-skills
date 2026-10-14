# matt-skills-on-openspec

[English](README.md) | **简体中文**

把 [Matt Pocock 的工程 Skill](https://github.com/mattpocock/skills) 接到 [OpenSpec](https://github.com/Fission-AI/OpenSpec) 工作流上。这些 Skill 默认把工作项写到 GitHub Issue 或本地 markdown，用在以 OpenSpec change 作为工作项的仓库里就会绕开 OpenSpec。这个 Skill 逐个说明 to-spec、to-tickets、wayfinder、triage 等 Skill 的产出该落到哪个 change 工件或哪条 `/opsx` 命令，哪些完全不用适配，以及怎么验证接线真的生效了。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill matt-skills-on-openspec
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
