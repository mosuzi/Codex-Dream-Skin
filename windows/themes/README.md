# 主题基线与配置

`assets/dream-skin.css` 是已固化的主题基线：全页背景、统一阅读蒙层、左栏与面板玻璃感、任务标题栏、设置页、输入框细边框、页脚透明化及无底部暗带都在这里维护。

创建新主题时，不要再改 CSS。复制 `theme-template.json`，只填下面的配置：

- `artPath`：本机图片的绝对路径，支持 PNG、JPG/JPEG、WebP；
- `brand.title` / `brand.subtitle`：首页主题标识；
- `art.overlay`：全页阅读蒙层；默认值是当前南宫婉主题验证过的深度；
- `art.position`：图片取景位置；默认值保持人物朝右的布局；
- `art.size`：通常保持 `cover`，以保证窗口再高也不会露出底部兜底色。
- `composer`：输入框的实体底色、边框色和内侧细线色；默认值是已验证的 Windows 目标模式样式。

例如：

```powershell
Copy-Item .\themes\theme-template.json .\themes\my-theme.json
notepad .\themes\my-theme.json
.\scripts\use-dream-theme.ps1 -ProfilePath .\themes\my-theme.json -Reapply
```

`active.json` 是当前启用的配置；切换脚本会先校验图片存在，再原子替换它。`nangong-wan.windows.json` 是当前完成版的 Windows 可恢复预设。
