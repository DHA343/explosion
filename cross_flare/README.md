# CrossFlare

動画の分析に基づく、出現から消滅まで1回再生する3Dビルボード。
十字と独立したリングの形をシェーダーで描画する。配色にはグラデーションを使う。

## 3種類のVariant

- Cross Only：十字が拡大・回転し、細長い残光になって消える。
- Single Ring：斜めの小リングが開き、太さの偏った単リングが拡大・分断・消失する。
  十字は残り、細長くなって消える。
- Double Ring：横に膨らむ十字と大小2本のリングが現れる。内外の太い側は半周ずらす。
  リングが拡散する段階で十字が一瞬幅広い四芒星になり、その後細長くなって消える。

円弧は消滅過程であり、独立した種類にはしていない。
形状・太さ・角度は動画の観察をもとに調整した近似値。元の作画データではない。

## 使用

`cross_flare.tscn` を3Dシーンにインスタンス化する。既定では0.5秒で1回再生し、
消滅後に停止する。ノードは残り、`play()` で最初から再生できる。
自然に再生を完了すると `finished` を1回通知する。解放する場合は利用側で扱う。
`playing = false` で一時停止、`playing = true` で続行する。
`seek(seconds)` は表示時刻だけを変更し、再生状態の変更や完了通知は行わない。

| 設定 | 内容 |
| --- | --- |
| Variant | Cross Only / Single Ring / Double Ring |
| Size | 描画面の半幅（m） |
| Brightness | 加算する光の強さ |
| Palette | 十字とリングのグラデーションを持つShaderMaterialプリセット |
| Angle | ビルボード面内での全体の開始角度（度） |
| Duration | 1回の出現から消滅までの時間（秒） |
| Autoplay | 実行時に自動で1回再生 |
| Stepped | 既定は無効。有効時は指定FPSの実時間サンプルで全体を更新 |
| Stepped FPS | Stepped時のサンプリングFPS（1〜60） |

基本モーションは寿命0〜1の正規化時間で評価する。Stepped時は形状、回転、リング、分裂、
フェード、発光、Gradient移動を同じ実時間サンプルで評価する。
流れる配色はビルボード面の座標で評価し、十字と大小リングで共有する。
形の回転から独立して色面を移動する。
色面の両端はクランプし、寿命中に無制限に循環させない。
単体は外部のカメラ参照を必要とせず、通常の3D遮蔽に従う。影は落とさない。
加算合成のため背景と表示サイズで見え方が変わる。にじみはシェーダーにも含む。

## プレビュー

`cross_flare_preview.tscn` は、暗い背景内へCrossFlareを画面内のランダムな位置に
継続生成する確認用Scene。Preview上のUIや固定比較表示は持たない。

Paletteは `cross_flare/palettes/` 直下のShaderMaterial `.tres` を起動時に自動取得する。
Palette、Spawn位置、Spawn間隔はPreviewが決定する。CrossFlareのVariant、Size、Brightness、
Angle、Duration、Color Flow Offset、Breakup、Halo等の個体差は、CrossFlare自身が生成時に決定する。
初期個体は再生時刻をずらして生成され、通常Spawnは0秒から再生する。
終了したCrossFlareはPreview側で自動解放する。

初期生成数、最大同時数、Spawn間隔、画面端Margin、SeedなどはPreview本体のInspectorで調整する。

## 配色の編集

`palettes/` の `.tres` がプリセット。既定Paletteは `cross_flare.tscn` 側でResource参照として設定する。
PaletteのShader Parametersで、`cross_gradient` と `ring_gradient` 内のGradientを編集する。
全Paletteは常にGradient方式で時間移動する。`flow_speed = 0` で停止し、負値で逆方向へ流れる。
`flow_speed` はGradient座標／秒の実時間値で、`duration` によって速度は変化しない。
`flow_direction` は軸方向（rad）、`flow_position` は時刻0の位置、`flow_width` は色面の幅を表す。
PaletteごとにFlow Speed / Direction / Position / Widthを設定する。
`ring_color_offset` と `inner_color_offset` はRing Gradient座標への追加オフセットとして使用する。
CrossFlare側のFlow Direction Offset（度）、Flow Speed Offset、Flow Position Offset、
Flow Width Offsetで個体ごとに補正する。PaletteのShaderMaterial自体は共有できる。

## 個体ランダム化

CrossFlareは各パラメータの直後にRandom幅を持つ。RuntimeでNodeが生成された際に一度だけ、
元の値へ±Random幅を加えて個体値を確定する。Random幅が0ならその値は固定される。
`play()` や `seek()` では再抽選しない。Editorではランダム化せず、Inspectorの値をそのまま使用する。

## 回転と欠け

角度は生存時間に対して一定方向・一定速度で進める。終盤も長い腕の軸を入れ替えず、もう一方を徐々に短くする。
登場時は細い側にも幅を残した閉じた輪。消滅直前に隙間を徐々に広げる。
単リングは既定で細い側の160度の範囲に分裂を入れ、長い弧を残す。
二重の外リングは既定で全周を分裂する。内リングは独立して早く消え、太さの偏りは外側と反対。

Island Count（3〜5）は分裂完了時の幾何学的な島の総数。残る長い弧も1個に数える。
Split Seedを変えると隙間の位置と幅が変わる。同じシードなら再生・シークで同じ形になる。
Split Directionは太い側を0度とした分裂範囲の中心。180度が細い側。
Split Rangeは適用角度幅、Split Irregularityは配置と幅のばらつき。
Gap Ratioは各区間のうち隙間にする割合。隙間と島の最小幅は区間幅から確保する。
Split Start / Endは寿命の0〜1で指定する。EndがStart以下なら最短0.001の区間にする。
リングの消滅は進行7/15までなので、分裂時刻もその前に設定する。
島の数は破片が十分見える時点の目標で、にじみ・背景・遮蔽・消滅中の可視数は変わる。

## 輪郭

Edge Softnessは十字・リング・分裂した端の輪郭のぼかし幅（エフェクト半幅に対する値）。
Halo Strengthは外に広がる光の強さで、輪郭のぼかしとは独立。
0でも画素単位のアンチエイリアスは残す。強いぼかしでは細い部分が淡くなり、隙間も狭く見える。
描画用Quadを1.2倍にして余白を確保し、本体の見かけのサイズは維持する。

## 検証

Godot 4.7.2 / Forward+でインポート、CrossFlare単体Scene、PreviewのランダムSpawn、
Palette自動取得、同時存在数制限、終了個体の解放を確認する。
追加機能は実描画の比較で、初期個体の時刻ずらし、各個体のPalette・Variant・サイズ・寿命・
Flow Offset・Breakup・Haloの差、画面Aspect Ratioへの追従を確認する。
