# GraphDB Tantivy 分支补充说明

这个分支只新增一项面向 GraphDB 的能力：**可配置的 BM25 参数**。

## 新增内容

### `Bm25Params`

新增 `Bm25Params` 结构体，用于配置每个索引的 BM25 参数：

- `k1`: 词频饱和参数
- `b`: 文档长度归一化参数

默认值保持不变：

- `k1 = 1.2`
- `b = 0.75`

### `IndexSettings::bm25_params`

在 `IndexSettings` 中新增可选字段：

- `bm25_params: Option<Bm25Params>`

如果不显式设置，行为与上游完全一致，仍然使用默认 BM25 参数。

### 序列化兼容

`bm25_params` 会写入 `meta.json`，但旧索引文件在缺少该字段时仍可正常读取。

## 使用示例

```rust
use tantivy::index::Bm25Params;
use tantivy::{Index, IndexSettings};

let settings = IndexSettings {
    bm25_params: Some(Bm25Params { k1: 1.5, b: 0.6 }),
    ..Default::default()
};

let index = Index::create_in_dir(path, schema, settings)?;
let params = index.bm25_params();
assert_eq!(params.k1, 1.5);
assert_eq!(params.b, 0.6);
```

## 说明

- 这份分支文档只描述本分支新增的功能，不重复上游已有内容。
- 如果不使用 `bm25_params`，这份分支与上游的搜索行为保持一致。
