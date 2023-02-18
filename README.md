# azooKey_dictionary_builder

azooKeyの辞書をビルドするためのパッケージです。

## インストール

```bash
sh ./install.sh
```

## 使い方

```bash
# loudsのビルド
azooKey_dictionary_builder louds ./worddict/ ./louds/ --gitkeep --clean
# costのビルド
azooKey_dictionary_builder cost ./ --gitkeep --clean
```

## テスト

```
swift test
```

