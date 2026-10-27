# daohui-data: DaoHui's public Rime data

This folder is a copy of `output/data_daohui/` of the Windows fork
(`D:\src\daohui`), built by `tools/package_daohui_data.py` of the input-method
project (<https://github.com/TimLin-1231/rime-asus-zhuyin>). The files are
unchanged except that git stores text files with LF line endings
(`.gitattributes`; the generator writes some with CRLF on Windows). It contains no
private data; sources and licences are in `DAOHUI_DATA_LICENSES.txt`, and
`FILES.txt` lists every file. Do not edit the files here: regenerate them there
and copy the whole folder again.

The build copies every file listed in `FILES.txt` into
`DaoHui.app/Contents/SharedSupport/` (keeping `lua/` and `opencc/`), except
`weasel.yaml`, the Windows frontend's settings; the macOS look is in
`data/squirrel.yaml`. See `package/copy_daohui_data` and `DAOHUI.md`.

`default.yaml` replaces the stock (plum) one: its root `__patch` makes
`asus_zhuyin` the only schema, then applies the user's `default.custom.yaml`.

Not here on purpose: the 410 MB language model `wanxiang-lts-zh-hant.gram`
(CC-BY-4.0, to be downloaded into the user folder `~/Library/DaoHui`), the
developer's personal words and learned data, and the Taiwan MOE dictionaries
(`terra_pinyin.tw.dict.yaml` is an empty stub).

Refresh (on the Windows machine):

```
python D:\Document\輸入法\tools\package_daohui_data.py
rm -r daohui-data/lua daohui-data/opencc
cp -r D:/src/daohui/output/data_daohui/. daohui-data/
```
