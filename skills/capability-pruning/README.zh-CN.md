# capability-pruning

[English](README.md) | **简体中文**

以能力为单位的项目精简方法论。项目做久了，很多能力早已没人用，连负责人自己都忘了它们还在；让 LLM 按技术症状找死代码只能找到零星几处，还很爱想当然地断言「从没用过」。所以先从规格和公开入口全量盘点，每项能力配一张证据卡片（用途、来由、规模、真实使用情况），分批交给负责人逐项拍板，获批的删除自顶向下一次删干净。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill capability-pruning
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
