# repo-audit-loop

[English](README.md) | **简体中文**

循环式仓库审计。LLM 做审计很容易抽查三分之一就号称「已审阅全仓」，报告里顺口提到的缺陷也常常没人跟进。这个 Skill 用覆盖台账把审计范围对账到 100%，用缺陷台账接住每一个未修的问题，多个互不重叠的视角并行审计（代码质量、规格与代码同步、逐个实跑公开入口、门禁盲区），谁发现谁修，一轮接一轮，直到某一轮零发现为止。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill repo-audit-loop
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
