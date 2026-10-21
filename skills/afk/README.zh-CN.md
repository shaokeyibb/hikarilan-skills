# afk

[English](README.md) | **简体中文**

你不在的时候让 agent 继续干活。告诉它要离开多久（默认 8 小时）：小事它自己定，能回退的先做、等你回来裁决，不可逆或对外的事一律挂起。每 30 分钟一次巡检，对着账本对齐进度；你回来时它给出一份总结，所有待裁决的事一并交给你。

## 用法

| 你输入 | 发生什么 |
|---|---|
| `/afk` | 开始 8 小时的 afk；afk 进行中再输入，则收尾。 |
| `/afk 1h` | 开始 1 小时的 afk；afk 进行中输入，则把截止时间改为从现在起 1 小时。 |
| `/afk 2h 只动 docs/` | 时长加要求。afk 期间给出的其他文字都按要求执行。 |
| 「我回来了」 | 收尾：先给总结，再把所有待裁决的事交给你逐条裁决。 |

决断分三档：**A** 自己定，**B** 做成可回退的形态、等用户回来裁决，**C** 挂起。所有记录都写进 `/tmp/afk-<uid>/` 下的账本，上下文压缩后也不会丢。

## 各个 agent 怎么跑

不同的只是定时巡检这一环，skill 会自己选对的那种：

- **Claude Code** 用 `CronCreate`。
- **Codex** 用 `scripts/ticker.sh` 配合 `codex queue`。Codex 的默认沙箱会拦它，所以唤醒器要在你离开前、经你批准一次提权后启动。
- **在 tmux 里的任何 agent** 可以用 `scripts/ticker.sh` 配合 `tmux send-keys`。
- **其他情况** 退回自驱循环，整个过程不结束回合。想支持别的 agent，往 skill 里那张投递命令表加一行配方即可。

会话必须一直开着：会话退出或机器休眠，巡检就停。

## 安装

```bash
npx skills add shaokeyibb/hikarilan-skills --skill afk
```

加上 `-g` 则装到用户级，而不是当前项目。

完整内容见 [SKILL.md](SKILL.md)；合集里的其他 skill 见[仓库首页](../../README.zh-CN.md)。
