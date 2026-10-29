【島輝】輸入法 DaoHui for macOS
===============================

島輝是 [【鼠鬚管】Squirrel](https://github.com/rime/squirrel) 的改名獨立分支，
由 RIME 團隊的鼠鬚管 1.1.2 修改而來，基於 中州韻輸入法引擎／Rime Input Method Engine 等開源技術。

DaoHui is a renamed, independent fork of Squirrel (鼠鬚管), the macOS frontend of
the Rime Input Method Engine, by the RIME team. It installs side by side with a stock
Squirrel: it has its own bundle identifier, input source id, app name, package id,
notification names, log folder and user folder (see [DAOHUI.md](DAOHUI.md)).

原作：式恕堂／RIME Developers（鼠鬚管）　分支：島輝貢獻者

授權條款：GPLv3（見 LICENSE.txt）

項目主頁：https://github.com/TimLin-1231/rime-asus-zhuyin

上游項目：https://github.com/rime/squirrel ／ https://rime.im

與鼠鬚管的差異
--------------

  * 改名為島輝，可與鼠鬚管同時安裝：不同的 bundle id
    （`io.github.timlin-1231.inputmethod.DaoHui`）、輸入法 id、程式名稱
    `~/Library/Input Methods/DaoHui.app`（安裝檔裝好後搬到登入使用者的資料夾）、
    安裝檔 id、通知名稱、log 資料夾 `$TMPDIR/rime.daohui`，使用者資料夾為
    `~/Library/DaoHui`。
  * 內建島輝的注音方案（`asus_zhuyin`，為預設方案）、Lua 模組與詞庫，
    以及仿華碩智慧輸入法的外觀（直式候選清單、行內預覽）。
  * 更新頻道指向島輝自己的 appcast，並在背景自動更新（不需輸入密碼，
    在沒有打字時安裝）。

安裝輸入法
----------

本品適用於 macOS 13.0+

安裝後請登出再登入，然後到「系統設定 › 鍵盤 › 輸入方式 › 編輯 › ＋ › 繁體中文」加入【島輝】。

使用輸入法
----------

選取輸入法指示器菜單裏的【島】字樣圖標，開始用島輝寫字。
連按兩下 Shift 切換中英文。macOS 預設把 Ctrl+Space 給「選取上一個輸入方式」，
要用 Ctrl+Space 切中英，請先在「系統設定 › 鍵盤 › 鍵盤快速鍵 › 輸入方式」關掉它。

定製輸入法
----------

用戶詞庫、配置文件位於 `~/Library/DaoHui`，可通過輸入法菜單中的「用戶設定」打開。
島輝沿用鼠鬚管的前端設定檔名稱 `squirrel.yaml`／`squirrel.custom.yaml`。

修改詞庫、配置文件後，須「重新部署」方可生效。

定製 Rime 的方法，請參考線上 [幫助文檔](https://rime.im/docs/)。前端樣式和行為與鼠鬚管相同。

從原始碼編譯：見 [DAOHUI.md](DAOHUI.md)。

致謝
----

島輝的程式幾乎全部來自鼠鬚管。以下為鼠鬚管原有的致謝。

輸入方案設計：

  * 【朙月拼音】系列

    感謝 CC-CEDICT、Android 拼音、新酷音、opencc 等開源項目

程序設計（鼠鬚管）：

  * 佛振
  * Linghua Zhang
  * Chongyu Zhu
  * 雪齋
  * faberii
  * Chun-wei Kuo
  * Junlu Cheng
  * Jak Wings
  * xiehuc

  查看更多 [代碼貢獻者](https://github.com/rime/squirrel/graphs/contributors)

美術：

  * 圖標設計 佛振、梁海、雨過之後（鼠鬚管）
  * 配色方案 Aben、Chongyu Zhu、skoj、Superoutman、佛振、梁海
  * 島輝圖標的「島」字以 Yuji Syuku 字型繪製 © 2021 The Yuji Project Authors，
    SIL Open Font License 1.1

本品引用了以下開源軟件：

  * Squirrel／鼠鬚管 (GNU General Public License v3.0)
  * Boost C++ Libraries  (Boost Software License)
  * capnproto (MIT License)
  * darts-clone  (New BSD License)
  * google-glog  (New BSD License)
  * Google Test  (New BSD License)
  * LevelDB  (New BSD License)
  * librime  (New BSD License)
  * librime 外掛 librime-lua、librime-octagram、librime-predict（授權見各項目）
  * OpenCC / 開放中文轉換  (Apache License 2.0)
  * plum / 東風破 (GNU Lesser General Public License 3.0)
  * Sparkle  (MIT License)
  * UTF8-CPP  (Boost Software License)
  * yaml-cpp  (MIT License)

島輝內建資料的來源與授權見 `DAOHUI_DATA_LICENSES.txt`（安裝後位於
`DaoHui.app/Contents/SharedSupport/`）。

問題與反饋
----------

島輝的問題請到 <https://github.com/TimLin-1231/rime-asus-zhuyin/issues> 反饋，
請不要把島輝特有的問題回報到鼠鬚管。

Rime 輸入法功能、使用方法與配置相關的問題，請參考 <https://github.com/rime/home>

謝謝 RIME 團隊與鼠鬚管的所有貢獻者！
