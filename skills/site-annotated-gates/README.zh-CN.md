# site-annotated-gates

[English](README.md) | **简体中文**

用静态门禁守住架构约束。LLM 很喜欢用读源码、断言代码结构的测试来「锁住」架构，结果正常重构也会挂；集中维护的豁免清单则越来越长，没人记得每条为什么在那儿。这个 Skill 把架构规则做成 lint 阶段的 AST 检查，例外直接以 `# gate-规则: 类别 — 理由` 的格式写在代码现场，未标注的站点和过期的标注都会报失败。附带一个只依赖标准库的实现。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill site-annotated-gates
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
