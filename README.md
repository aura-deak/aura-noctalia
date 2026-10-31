# DMS → Noctalia 移植说明
> [!NOTE]
> 大肥鱼，好样的！

> [!IMPORTANT]
> 这个移植使用的是我电脑里的某个未知版本（安装于26/9/26，因为shorin更新程序的保护机制而未能得到更新），而不是最新版  
> 另外，我自己也往里面加了一些符合个人习惯的新配置。可按`Mod + Shift + /`查看

把原来由 DMS（DankMaterialShell）提供的 shell 层功能，换成 Noctalia v5。
窗口管理、布局、动画、输入、窗口规则这些属于 compositor 的部分原样保留，Noctalia 不接管。

## 目录结构

```
noctalia/                        移植工程根目录（对应 ~/.config/niri/）
├── config.kdl                   主配置，dms → noctalia 改写
├── layout.kdl                   原样
├── animations.kdl               原样
├── blur.kdl                     原样
├── autostart.kdl                原样
├── vkms-output.kdl              原样
├── shorin-windowrules.kdl       原样，壁纸层 namespace 改了
├── scripts/
│   └── random-anime-wallpaper-noctalia   原 dms 版脚本，IPC 换成 noctalia msg
└── noctalia/                    对应原 ~/.config/niri/dms/
    ├── binds.kdl                所有 dms ipc 调用换成 noctalia msg
    ├── alttab.kdl               原样
    ├── supertab.kdl             原样
    ├── cursor.kdl               原样
    ├── outputs.kdl              原样
    ├── input.kdl                原样
    ├── layout.kdl               原样
    ├── windowrules.kdl          app-id 换成 noctalia
    ├── wpblur.kdl               壁纸层 namespace 改了
    └── config.toml              Noctalia shell 配置（由 dms/settings.json 迁移）
```

## 部署

1. 备份现有配置，然后把本目录内容合并进 `~/.config/niri/`，`noctalia/` 子目录一起放进去。
2. `noctalia/scripts/random-anime-wallpaper-noctalia` 复制到 `~/.local/bin/` 并 `chmod +x`。
3. `noctalia/config.toml` 复制到 `~/.config/noctalia/config.toml`。
4. 清掉旧的 GUI 覆盖，否则会盖住上面的配置：
   `~/.local/state/noctalia/settings.toml` 里的值优先级高于 `~/.config/noctalia/config.toml`，
   建议在 Noctalia 设置界面里重新确认一遍，或者先移走这个文件再启动。
5. 在 Noctalia 设置里启用 Niri 模板（或等主题应用后自动生成）`~/.config/niri/noctalia.kdl`，
   里面是主配置 `include optional=true "noctalia.kdl"` 引用的取色结果。
6. 停用 DMS：把 `dms` 的自启项去掉，确认 `noctalia --daemon` 能起来。

## polkit 认证代理

DMS 装在这台机器上的时候，系统里只有 `polkitd`，没有任何认证代理，所以 `pkexec` 会直接报
`Error creating textual authentication agent`，图形界面里也弹不出提权密码框。

Noctalia 自带一个原生 polkit 认证代理，不用再装 `polkit-gnome`、`hyprpolkitagent` 这类包。
配置里打开就行：

```toml
[shell]
polkit_agent = true

[shell.panel]
polkit_placement = "floating"   # 浮在屏幕上，也可以 attached 贴顶栏
polkit_position  = "center"     # auto | center | top_left | ...
```

`install.sh` 在拷完配置之后会补一条
`noctalia msg config-set shell.polkit_agent true`，让正在跑的实例立刻生效，不用重启。

验证：

```bash
pkexec true
grep -i polkit ~/.cache/noctalia/noctalia.log | tail -3
```

日志里出现 `registered Polkit authentication agent` 和
`polkit action "org.freedesktop.policykit.exec" authorized` 就说明通了。

注意：同一时间只能有一个认证代理注册到 `org.freedesktop.PolicyKit1`。
如果以后又装了别的 agent，要把这里改回 `false`，否则两者会抢注册，弹窗行为会很怪。

## IPC 对照

| DMS | Noctalia |
| --- | --- |
| `dms run` | `noctalia --daemon` |
| `dms ipc call settings focusOrToggle` | `noctalia msg settings-toggle` |
| `dms ipc call spotlight toggle` | `noctalia msg panel-toggle launcher` |
| `dms ipc call dankdash wallpaper` | `noctalia msg panel-toggle wallpaper` |
| `dms ipc call powermenu toggle` | `noctalia msg panel-toggle session` |
| `dms ipc call clipboard toggle` | `noctalia msg panel-toggle clipboard` |
| `dms ipc call lock lock` | `noctalia msg session lock` |
| `dms ipc call lock lock` + `systemctl suspend` | `noctalia msg session lock-and-suspend` |
| `dms ipc call wallpaper set <path>` | `noctalia msg wallpaper-set <path>` |
| `dms ipc call audio increment N` | `noctalia msg volume-up N` |
| `dms ipc call audio decrement N` | `noctalia msg volume-down N` |
| `dms ipc call audio mute` | `noctalia msg volume-mute` |
| `dms ipc call audio micmute` | `noctalia msg mic-mute` |
| `dms ipc call mpris playPause` | `noctalia msg media toggle` |
| `dms ipc call mpris previous/next` | `noctalia msg media previous/next` |
| `dms ipc call mpris increment/decrement N` | `noctalia msg media volume-up/volume-down N` |
| `dms ipc call brightness increment/decrement N` | `noctalia msg brightness-up/down N` |
| `dsearch serve` | 不需要，Noctalia 自带 launcher |

## 没有等价功能的部分

这些绑定在 `binds.kdl` 里已注释掉，保留位置方便以后接插件：

| 原功能 | 说明 |
| --- | --- |
| 记事本（Mod+Shift+N） | Noctalia 没有内置便签。官方有 `noctalia/notes` 插件，装好后用 `noctalia msg panel-toggle noctalia/notes` 代替。 |
| 任务管理器（Ctrl+Alt+Delete） | Noctalia 没有进程列表面板，只提供 sysmon 组件和 `services/system-monitor` 数据。 |
| 窗口规则编辑器（Mod+Shift+W） | Noctalia 不管理 niri 窗口规则，规则是文件。 |
| 重命名工作区（Ctrl+Shift+R） | Noctalia 无该 IPC，可用 `niri msg action rename-workspace` 配合输入框实现。 |


## 已做的校验

- `niri validate -c config.kdl` → config is valid（`noctalia.kdl` 未生成属于预期，是 optional include）
- `noctalia config validate noctalia/config.toml` → Config is valid
