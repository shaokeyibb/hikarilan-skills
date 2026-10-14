# e2e-first-testing

[English](README.md) | **简体中文**

以 E2E 测试为优先的测试方法论，必要时才用隔离测试（且先列全失败方式再写代码），少用乃至不用单元测试。LLM 编写的单元测试基本毫无意义、巨量且不会起到任何测试作用。与其让 LLM 再写这些无用的单测，还不如直接让 LLM 从项目入口开始写全面覆盖的 E2E 测试更有效。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill e2e-first-testing
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
