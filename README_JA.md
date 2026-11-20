# Oddworld: Abe's Oddysee — Invincible + Infinite Shrykull (R.E.L.I.V.E.)

[English](README.md) | **日本語**

Steam版 *Oddworld: Abe's Oddysee* をR.E.L.I.V.E.で動かし、次の機能を追加するソースパッチです。

- Abeを常時無敵化
- Shrykullを未取得のニューゲーム開始時から使用可能
- Shrykullを使用しても消費せず、何度でも再使用可能
- 画面移動やリスポーン後もShrykullの所有状態と必要リソースを維持
- Steam日本語版のフォント座標差を補正（実験的対応）
- 既存のコントローラー入力設定は変更しない

これはOddworld InhabitantsおよびAliveTeamの公式製品ではない、非公式ファンMODです。

## プレイ動画

[▶ 74秒・720pの動作デモを見る](media/oddworld-invincible-infinite-shrykull-demo-720p.mp4)

通常の取得イベントを行っていない序盤でのShrykull発動、Abeへ戻った後の再使用、敵の攻撃を受けても生存する無敵状態、およびSteam日本語版データを改造R.E.L.I.V.E.で実行する様子を収録しています。

## R.E.L.I.V.E.とは

[R.E.L.I.V.E.](https://github.com/AliveTeam/alive_reversing) は、AliveTeamが開発するファン製のオープンソース・エンジン再実装プロジェクトです。対象は初期Oddworldの次の2作品です。

- *Oddworld: Abe's Oddysee*（ソースコード上の略称: `AO`）
- *Oddworld: Abe's Exoddus*（ソースコード上の略称: `AE`）

ゲーム素材そのものを置き換える作品ではなく、購入済みゲームのLVL、動画、音声などを読み込んで動かす新しい実行エンジンです。元ゲームの処理をC++で再実装しているため、原作EXEの保護領域や実行時アドレスを推測するトレーナー方式より、ゲーム内部の意味に沿った変更を行えます。

R.E.L.I.V.E.の主な目的は次のとおりです。

- Oddysee／Exoddusエンジンの再実装
- 現代のWindows・Linux・SDL環境への対応
- 原作由来の不具合修正
- レベル編集・MOD制作の基盤
- エンジン挙動の研究と保存

R.E.L.I.V.E.自体はチート配布を主目的としていません。ただし、無敵フラグ、レベル選択、デバッグ処理、Shrykullの所有・消費処理などが読み取れるソースとして再実装されているため、今回のような機能を固定アドレスの推測なしに組み立てられます。

今回のMODは、R.E.L.I.V.E.のうちOddysee側（`Source/AliveLibAO`）を中心に変更しています。上流へ含まれている既成の「無限Shrykull」機能を有効化したものではなく、次の処理を新しく接続した派生パッチです。

- Abeの既存無敵フラグ
- Shrykull変身用リソースの先行ロード
- 所有フラグと使用可能タイマーの常時維持
- 使用終了時の消費処理抑止
- 画面移動・リスポーン時のリソース保持
- Steam日本語版専用フォント座標の選択

### 公式リンクとビルド元

- [R.E.L.I.V.E. 公式GitHubリポジトリ](https://github.com/AliveTeam/alive_reversing)
- [AliveTeam公式サイト](https://aliveteam.github.io/)
- [R.E.L.I.V.E. リリース一覧](https://github.com/AliveTeam/alive_reversing/releases)
- [今回のベースコミット `3be8967`](https://github.com/AliveTeam/alive_reversing/commit/3be8967b71b29e6e61009d291bd64dce39abf7ac)

このリポジトリはAliveTeamの公式ブランチや公式リリースではありません。不具合報告を上流へ送る前に、未改造R.E.L.I.V.E.でも再現するか確認してください。

## 機能仕様

### 1. Abeの常時無敵化

R.E.L.I.V.E.が再実装している原作由来の `gAbeInvulnerableCheat_5076E4` を、ゲーム開始時から有効にします。外部トレーナーでプロセスのアドレスを推測して書き換える方式ではなく、エンジンのソースコード側で既存の無敵判定を有効化しています。

主に次の通常ダメージを受けてもAbeが死亡しなくなります。

- Sligの銃撃
- Slog、Scrab、Paramiteなどによる通常攻撃
- 爆発や多くの危険オブジェクト
- 通常のダメージ／死亡処理を経由する攻撃

次のような処理は通常のダメージ判定を通らない場合があり、完全な無効化を保証しません。

- 画面外や奈落への落下
- ストーリー進行に伴う強制遷移
- 特殊演出専用の死亡・リセット
- エンジンが直接行うマップ再読み込み

### 2. Shrykullを未取得状態から使用可能

通常のOddyseeでは、鳥ポータルなどの条件を満たしてShrykullを獲得した後にだけ使用できます。このMODでは、ニューゲーム開始直後およびShrykull未取得の既存セーブを読み込んだ直後から、待機中のチャントでShrykullへ変身できます。

所有フラグだけを立てると、未取得プレイでは変身用データが読み込まれておらず不具合が起こります。そのため次の処理を一体として実装しています。

- `SHRYPORT.BND` からAbe／Shrykullの変身アニメーションを必要時に読み込む
- `SPLINE.BAN` からShrykull攻撃に必要なスプライン資源を読み込む
- 現在の所有状態 `field_16C_bHaveShrykull` を有効にする
- 復帰用の保存状態 `field_154_bSavedHaveShrykull` も有効にする
- 使用可能時間 `field_168_ring_pulse_timer` を現在フレームから32,000フレーム先へ継続更新する

この更新はAbe生成時だけでなくプレイ中にも行うため、Shrykullを持っていない古いセーブを読み込んでも即座に有効になります。インストーラーが既存セーブファイルを直接書き換えることはありません。

### 3. Shrykullの無限再使用

通常はShrykullが対象を倒して変身を終了すると、リングタイマーが消費されます。このMODでは `Shrykull::VUpdate_463AE0()` 内の消費要求 `field_122_bResetRingTimer` を立てないため、通常のAbeへ戻った直後から再びチャントできます。

さらに次の場面でも能力と必要資源を保持します。

- 同一レベル内の画面移動
- 別レベルへの移動
- Abeの死亡後のリスポーン
- Shrykull未取得セーブのロード
- Shrykullを一度使用した後

つまり「一度取得した後だけ無限」ではなく、**取得イベント自体を行わなくても最初から使用でき、その後も回数無制限**という仕様です。

### 4. Steam日本語版フォント対応

英語版R.E.L.I.V.E.は、メニュー用116字・掲示板用104字の英語版座標表を固定使用します。しかしSteam日本語版のフォント画像は文字の配置と収録数が異なるため、英語版の座標で切り出すと別の字形が表示されます。

このMODでは、検証済み日本語版 `AbeWin.exe` から利用者自身が生成した次の座標表を読み込みます。

- メニュー用フォント: 238エントリー
- LCD／掲示板用フォント: 238エントリー
- 合計ファイルサイズ: 1,904 bytes

また、R.E.L.I.V.E.が内部で追加表示する英語のラベルについては、日本語フォント画像に収録されている英大文字と数字へ割り当てます。座標表が見つからない、またはサイズが不正な場合は、エンジンを停止させず英語版座標表へフォールバックしてログへ警告を記録します。

この日本語対応は検証済みSteam版専用の実験的機能です。日本語版フォントに一般的なASCII小文字・記号一式が存在しないため、R.E.L.I.V.E.独自の英語ラベルは大文字表示になり、一部の記号は空白として扱われます。すべての画面・全文章について完全な日本語表示を保証するものではありません。

### 5. コントローラー

このパッチは入力処理、ボタン割り当て、`abe.ini` を変更しません。コントローラー対応はR.E.L.I.V.E.／SDL3の既存機能をそのまま使用します。検証環境ではNintendo Switch Pro Controllerが認識されましたが、機種固有の割り当て変更は含みません。

### 6. 起動方式と元ファイルの保護

- 実行対象をAbe's Oddysee（AO）へ固定
- MODフォルダ配置時にゲームルートを検出可能
- 元の `AbeWin.exe`、LVL、動画、音声を上書きしない
- 通常版とMOD版を別々に起動可能
- 固定アドレスを推測してSteam版EXEを直接パッチしない

元ゲームへ完全に戻す場合はMOD版を終了し、Steamまたは元の `AbeWin.exe` から起動するだけです。

## 公開内容

このリポジトリは、ゲーム本体、抽出したゲームデータ、元の実行ファイル、抽出済みフォント表、R.E.L.I.V.E.本体のソース一式、コンパイル済み実行ファイルを含みません。利用者が録画した短いプレイ動画だけをデモとして収録します。

- `patches/invincible-infinite-shrykull-japanese.patch` — 上流R.E.L.I.V.E.へ適用する差分
- `tools/Extract-JapaneseFontAtlas.ps1` — 購入済みのSteam日本語版からフォント座標表をローカル生成するツール
- `NOTICE.md` — 出典、対象バージョン、再配布上の注意
- `media/oddworld-invincible-infinite-shrykull-demo-720p.mp4` — 圧縮済み74秒のプレイ動画

## 対象

- Steam App ID: `15700`
- Steam build ID: `252109`
- 上流R.E.L.I.V.E. commit: `3be8967b71b29e6e61009d291bd64dce39abf7ac`
- `AbeWin.exe` SHA-256: `86D982094B9426F934B1B1925DA44766BBB524D430D203A5B94DC16F036C48E1`
- Windows x64 / SDL 3.4.18で検証

異なるゲーム版では、日本語フォント抽出位置が一致しない可能性があります。検証済みハッシュ以外のEXEに抽出ツールは処理を行いません。

## ビルド

### 1. R.E.L.I.V.E.を取得

```powershell
git clone --recursive https://github.com/AliveTeam/alive_reversing.git
cd alive_reversing
git checkout 3be8967b71b29e6e61009d291bd64dce39abf7ac
```

### 2. パッチを適用

```powershell
git apply C:\path\to\invincible-infinite-shrykull-japanese.patch
```

`git apply --check` を先に実行すると、変更可能かだけを確認できます。

### 3. x64 Releaseでビルド

R.E.L.I.V.E.公式READMEに従い、CMake、Visual Studio、SDL3を用意してビルドします。

```powershell
cmake -S . -B build-mod -A x64 -DSDL3_DIR=C:\path\to\SDL3\cmake
cmake --build build-mod --config Release --target relive
```

## 日本語フォント表の生成

ゲームを終了してから、PowerShellで次を実行します。

```powershell
.\tools\Extract-JapaneseFontAtlas.ps1 `
  -GameDirectory "D:\SteamLibrary\steamapps\common\Oddworld Abes Oddysee" `
  -OutputPath "C:\path\to\mod\japanese_font_atlas.bin"
```

ツールは元の `AbeWin.exe` を非表示で短時間起動し、検証済み日本語版の展開済みメモリから2種類・各238字の座標表だけを取得します。元EXE、LVL、設定、セーブデータは変更しません。

生成されるファイル:

- サイズ: `1,904 bytes`
- SHA-256: `235E5B729CFFC9C1C818BEF553926DEC1CEA025A9E0BE41A5D0A3E6F2DE03C89`

## 導入

ビルドした `relive.exe`、対応する `SDL3.dll`、生成した `japanese_font_atlas.bin` を同じMODフォルダへ置きます。ゲームの作業ディレクトリをSteam版のルートにして起動してください。

元の `AbeWin.exe` は上書きしません。通常版へ戻すにはMOD版を終了し、Steamまたは元の `AbeWin.exe` から起動します。

## 動作確認

1. Shrykull未取得のニューゲームまたはセーブを開始する。
2. Abeの待機中にチャントし、Shrykullへ変身できることを確認する。
3. 使用終了後に再びチャントし、再使用できることを確認する。
4. 敵の攻撃や爆発でAbeが死亡しないことを確認する。
5. メニュー、ポーズ画面、掲示板の文字表示とコントローラー操作を確認する。

ゲーム進行用の強制遷移、特殊演出、画面外落下など、通常ダメージ処理を通らない死亡・リセットまで無効になるとは限りません。

## Credits

- [AliveTeam / R.E.L.I.V.E.](https://github.com/AliveTeam/alive_reversing)
- [SDL](https://github.com/libsdl-org/SDL)
- *Oddworld: Abe's Oddysee* © its respective rights holders

このリポジトリ独自の文書および抽出ツールはMIT Licenseです。R.E.L.I.V.E.へ適用されるパッチ部分には、上流プロジェクトおよび各依存物の条件も適用されます。詳細は `NOTICE.md` を参照してください。


