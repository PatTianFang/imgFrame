# 贡献指南

## 开发流程

1. 从主分支创建功能分支。
2. 修改代码后执行 `flutter analyze` 和 `flutter test`。
3. 提交 PR 时说明功能变更、测试结果和潜在风险。

## 代码组织

新增业务优先放入 `lib/src/features/<feature_name>/`，并按以下结构组织：

- `domain`：实体、枚举、值对象。
- `data`：插件适配、文件 IO、图片处理、持久化。
- `application`：状态管理和用例编排。
- `presentation`：页面和组件。

## 提交建议

提交信息建议使用简短动词开头，例如：

- `feat: add custom frame preset`
- `fix: handle missing aperture exif`
- `docs: update build instructions`

## 发布前检查

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows --release
flutter build apk --release
```
